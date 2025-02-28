#!/usr/bin/perl -w

# Gain access to all the pragmas and modules we'll need.
use strict;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Basename;
use File::Path qw( make_path );
use File::Spec;
use File::chdir;
use Text::CSV;
use URI;
use WWW::Mechanize;

# Make a forward declaration of our subroutines.
sub main();
sub downloadAbaChecklist();
sub makeChecklistDirFullPath($);
sub saveAbaChecklistFile($$$);
sub parseAbaChecklist($);
sub makeSymbolicLink($$);

# Define constants we need.
#
# TODO: Specify this URL via a configuration file.
$::ABA_CHECKLIST_URL = 'https://www.aba.org/aba-checklist/';
$::CSV_HEADER_ROW =
  [
   'Group Name',
   'Species Name English',
   'Species Name French',
   'Species Latin Name',
   'Species Code',
   'Species Abundance'
  ];
$::LOCAL_CHECKLIST_DIR = 'checkLists';
$::LOCAL_CHECKLIST_SUBDIR_PARSED = 'parsed';
$::LOCAL_CHECKLIST_SUBDIR_RAW = 'raw';

# Call the main subroutine, returning its return value to our caller.
exit main();

sub main() {
  my $rawChecklistFilename;

  # TODO: Make a config switch to enable or disable the download.
  if (1) {
    # Download the checklist file from the official source.
    $rawChecklistFilename = downloadAbaChecklist();
  }
  else {
    # In lieu of downloading, just point to a local file already in place.
    $rawChecklistFilename = File::Spec->catfile(
                                                makeChecklistDirFullPath($::LOCAL_CHECKLIST_SUBDIR_RAW),
                                                # TODO: Get name from config.
                                                'ABA_Checklist-8.17.csv'
                                               );
  }

  # Do the local parsing to get the checklist file ready for searching.
  my $parsedChecklistFilename = parseAbaChecklist($rawChecklistFilename);

  # TODO: Specify this name via a configuration file.
  my $linkFilename = File::Spec->catfile(
                                         makeChecklistDirFullPath($::LOCAL_CHECKLIST_SUBDIR_PARSED),
                                         # TODO: Get name from config.
                                         'latest.checklist.parsed.csv'
                                        );

  # TODO: Put these messages behind a config switch or log level setting.
  if (1) {
    print "Parsed filename = [$parsedChecklistFilename]\n";
    print "Linked filename = [$linkFilename]\n";
  }

  # TODO: Put this message behind a config switch or log level setting.
  if (1) {
    print "Before making symbolic link, \$CWD = [$CWD]\n";
  }

  # Create a symbolic link to the parsed checklist file for searching.
  makeSymbolicLink($parsedChecklistFilename, $linkFilename);

  # TODO: Put this message behind a config switch or log level setting.
  if (1) {
    print "After making symbolic link, \$CWD = [$CWD]\n";
  }
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
  my $checklistDirFullPath = makeChecklistDirFullPath($::LOCAL_CHECKLIST_SUBDIR_RAW);

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

sub makeChecklistDirFullPath ($) {
  my $checklistSubdir = shift();

  return File::Spec->catfile(
                             dirname(__FILE__),
                             $::LOCAL_CHECKLIST_DIR,
                             $checklistSubdir
                            );
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

  my $outputDirFullPath = makeChecklistDirFullPath($::LOCAL_CHECKLIST_SUBDIR_PARSED);
  my $outputFileFullPath = File::Spec->catfile(
                                               $outputDirFullPath,
					       $outputFileBaseName
					      );

  # TODO: Put these messages behind a config switch or log level setting.
  if (1) {
    print "Input filename  = [$inputFileFullPath]\n";
    print "Output filename = [$outputFileFullPath]\n";
  }

  my $encoding = ":encoding(UTF-8)";
  my $inputFileHandle = undef;
  my $outputFileHandle = undef;
  my @rows = ();

  # Open the species input file so we can do our processing.
  open(
       $inputFileHandle,
       "< $encoding",
       $inputFileFullPath
      )
    || die("$0: can't open $inputFileFullPath for reading: $!");

  # TODO: Put this message behind a config switch or log level setting.
  if (1) {
    print "About to check for output directory [$outputDirFullPath]...\n";
  }

  # Create the output directory if it does not already exist.
  if (! -d $outputDirFullPath) {

    # TODO: Put this message behind a config switch or log level setting.
    if (1) {
      print "Did not find output directory [$outputDirFullPath], attempting to create...\n";
    }

    make_path($outputDirFullPath) or die "Failed to create output directory [$outputDirFullPath]: $!";

    # TODO: Put this message behind a config switch or log level setting.
    if (1) {
      print "Created output directory [$outputDirFullPath].\n";
    }
  }
  else {
    # TODO: Put this message behind a config switch or log level setting.
    if (1) {
      print "Found output directory [$outputDirFullPath].\n";
    }
  }

  # Open the species output file so we can do our processing.
  open(
       $outputFileHandle,
       "> $encoding",
       $outputFileFullPath
      )
    || die("$0: can't open $outputFileFullPath for writing: $!");

  # Get ready to operate on the CSV files.
  my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });

SPECIES:
  while (my $row = $csv->getline($inputFileHandle)) {
    my ($group, $speciesNameEnglish, $speciesNameFrench, $speciesLatinName, $speciesCode, $speciesAbundance) = @$row;

    if ($speciesCode) {
      push(@rows, $row);

      # TODO: Put this message behind a config switch or log level setting.
      if ("") {
        print "Found species code [$speciesCode] with English species name [$speciesNameEnglish].\n";
      }
    }
  }

  close($inputFileHandle) or die "Failed to close $inputFileFullPath: $!";

  if (scalar(@rows) > 0) {
    unshift(@rows, $::CSV_HEADER_ROW);
    $csv->say($outputFileHandle, $_) for @rows;
  }

  close($outputFileHandle) or die "Failed to close $outputFileFullPath: $!";

  return $outputFileFullPath;
}

sub makeSymbolicLink($$) {
  my $oldFileFullPath = shift();
  my $newFileFullPath = shift();

  my $dirname = dirname($oldFileFullPath);
  my $oldFileBasename = basename($oldFileFullPath);
  my $newFileBasename = basename($newFileFullPath);

  # TODO: Put these messages behind a config switch or log level setting.
  if (1) {
    print "Directory name = [$dirname]\n";
    print "Old file basename = [$oldFileBasename]\n";
    print "New file basename = [$newFileBasename]\n";
  }

  local $CWD = $dirname;

  if (-l $newFileBasename) {
    unlink($newFileBasename) or die "Failed to remove link file [$newFileBasename]: $!";
  }

  symlink($oldFileBasename, $newFileBasename) or die "Failed to link old file [$oldFileBasename] to new file [$newFileBasename]: $!";
}

# End of script.
