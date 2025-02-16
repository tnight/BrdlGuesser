#!/usr/bin/perl -w

# Gain access to all the pragmas and modules we'll need.
use strict;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Basename;
use File::Spec;
use Text::CSV;
use URI;
use WWW::Mechanize;

# Make a forward declaration of our subroutines.
sub main();
sub downloadAbaChecklist();
sub saveAbaChecklistFile($$$);
sub parseAbaChecklist($);

# Define constants we need.
$::ABA_CHECKLIST_URL = 'https://www.aba.org/aba-checklist/';
$::LOCAL_CHECKLIST_DIR = 'checkLists';
$::LOCAL_CHECKLIST_SUBDIR_PARSED = 'parsed';
$::LOCAL_CHECKLIST_SUBDIR_RAW = 'raw';

# Call the main subroutine, returning its return value to our caller.
exit main();

sub main() {
  # TODOTODO: Put back after testing.
  # my $checklistFilename = downloadAbaChecklist();
  my $checklistFilename = 'checklists\\raw\\ABA_Checklist-8.17.csv';
  parseAbaChecklist($checklistFilename);
}

sub downloadAbaChecklist() {
  my $mechAgent = WWW::Mechanize->new();
  my $response = $mechAgent->get($::ABA_CHECKLIST_URL);
  if ($response->is_success) {
    my $content = $response->decoded_content;
  }
  else {
    die $response->status_line;
  }

  my @links = $mechAgent->links();
  if (scalar(@links) == 0) {
    die "Found no links in downloaded web page!";
  }

  my ($csvUrl, $pdfUrl);

  foreach my $link (@links) {
    if (! defined($link->text)) {
      next;
    }

    if ($link->text eq 'CSV') {
      $csvUrl = $link->url;
    }
    elsif ($link->text eq 'PDF') {
      $pdfUrl = $link->url;
    }
  }

  if (!defined($csvUrl) || !defined($pdfUrl)) {
    die "Unable to determine CSV link and/or PDF link.";
  }

  print "\$csvUrl = [$csvUrl]\n\$pdfUrl = [$pdfUrl]\n";

  # Get the path to the checklist directory including the path of the
  # running script.
  my $checklistDirFullPath = File::Spec->catfile(
						 dirname(__FILE__),
						 $::LOCAL_CHECKLIST_DIR,
						 $::LOCAL_CHECKLIST_SUBDIR_RAW
						);

  # Download the PDF file.
  my $pdfFileFullPath = saveAbaChecklistFile(
					     $mechAgent,
					     $pdfUrl,
					     $checklistDirFullPath
					    );

  # Download the CSV ZIP file.
  my $csvZipFileFullPath = saveAbaChecklistFile(
						$mechAgent,
						$csvUrl,
						$checklistDirFullPath
					       );

  # Open the ZIP archive.
  my $zip = Archive::Zip->new();
  unless($zip->read($csvZipFileFullPath) == AZ_OK) {
    die "Unable to read ZIP file [$csvZipFileFullPath]: $!";
  }

  # Find the correct entry within the ZIP archive. We need to exclude any
  # files whose names start with underscores (__).
  my @csvFileMembers = $zip->membersMatching( '^[^\W_].*\.csv' );

  if (scalar(@csvFileMembers) == 0) {
    die("Did not find any CSV file in the ZIP archive [$csvZipFileFullPath]");
  }
  elsif (scalar(@csvFileMembers) > 1) {
    my $errorMessage = "Found more than one CSV file in the ZIP archive [$csvZipFileFullPath]; found these CSV files: ";
    foreach my $member (@csvFileMembers) {
      $errorMessage .= "[" . $member->fileName() . "], ";
    }
    $errorMessage .= "exiting";
    die($errorMessage);
  }

  # Build the full path to the output file including our output path.
  my $csvMember = $csvFileMembers[0];
  my $csvMemberFilename = $csvMember->fileName();
  my $outputFileFullPath = File::Spec->catfile(
					       $checklistDirFullPath,
					       $csvMemberFilename
					      );

  # Update the modified date and time of the CSV file to be the current
  # date and time. This matches the modified date and time of the
  # downloaded PDF file and reduces confusion about which file is the
  # latest one downloaded.
  $csvMember->setLastModFileDateTimeFromUnix(time());

  # Extract the CSV file from the ZIP archive.
  unless($csvMember->extractToFileNamed($outputFileFullPath) == AZ_OK) {
    die("Unable to extract CSV file [$csvMemberFilename] from ZIP archive [$csvZipFileFullPath]: $!");
  }

  # Remove the ZIP archive now that we have extracted the CSV file.
  undef($zip);
  unlink($csvZipFileFullPath);

  # Return the name of the local, extracted CSV file.
  return $outputFileFullPath;
}

sub saveAbaChecklistFile($$$) {
  my $mechAgent = shift();
  my $sourceUrl = shift();
  my $checklistDirFullPath = shift();

  my $response = $mechAgent->get($sourceUrl);
  if (! $response->is_success) {
    die $response->status_line;
  }

  # Save the PDF file locally.
  my $localFileFullPath = File::Spec->catfile(
					      $checklistDirFullPath,
					      (URI->new($sourceUrl)->path_segments)[-1]
					     );
  if (! open(FOUT, ">$localFileFullPath")) {
    die("Could not create local file [$localFileFullPath]: $!");
  }
  binmode(FOUT); # required for Windows
  print(FOUT $response->content());
  close(FOUT);

  return $localFileFullPath;
}

sub parseAbaChecklist($) {
  my $inputFileFullPath = shift();

  my $inputFileBaseName = basename($inputFileFullPath);
  my $outputFileBaseName = $inputFileBaseName;
  $outputFileBaseName =~ s/\.csv$/.parsed.csv/;
  my $outputFileFullPath = File::Spec->catfile(
					       $::LOCAL_CHECKLIST_DIR,
					       $::LOCAL_CHECKLIST_SUBDIR_PARSED,
					       $outputFileBaseName
					      );

  print "Input filename =  [$inputFileFullPath]\n";
  print "Output filename = [$outputFileFullPath]\n";

  die("parseAbaChecklist() subroutine not yet implemented!");
}

# End of script.
