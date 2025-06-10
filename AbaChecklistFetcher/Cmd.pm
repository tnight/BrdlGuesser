# I tried using the "new" (as of 2025) Corinna framework for this class,
# but the App::Cmd framework complained that the class hierarchy was not
# as it expects. Maybe someday the different frameworks will work
# together? Until then, we have to use the old school Perl OO syntax.
#
# More information about Corinna can be found here:
# https://dev.to/ovid/bringing-modern-oo-to-perl-51ak

package AbaChecklistFetcher::Cmd;

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make our superclass known.
use parent qw(App::Cmd::Simple);

# Gain access to all the other modules we'll need.
use Archive::Zip qw( :CONSTANTS :ERROR_CODES );
use File::Path qw( make_path );
use File::Spec;
use File::chdir;
use FindBin;
use My::Config;
use Text::CSV;
use URI;
use WWW::Mechanize;

#
# Constants
#

# The file encoding we use for parsing CSV files.
use constant ENCODING => ":encoding(UTF-8)";

# Define our usage message as a constant.
use constant USAGE_DESCRIPTION => <<END;
%c

This command will fetch the latest version of the bird species list from
the website of the American Birding Association (ABA) and format the
list for processing by the BRDL guesser script.
END

# Expose our application version for use by the "version" command.
use constant VERSION => 1.01;

#
# Constructor
#

sub new($$) {
  my ($class, $arg) = @_;

  # First, call the constructor of our superclass.
  my $self = $class->SUPER::new($arg);

  # Then, initialize the additional items we need for this subclass.
  $self->{'checklistDirFullPathParsed'} = undef;
  $self->{'checklistDirFullPathRaw'} = undef;
  $self->{'config'} = undef;
  $self->{'csvFileFullPathParsed'} = undef;
  $self->{'csvFileFullPathRaw'} = undef;
  $self->{'csvFileHandleParsed'} = undef;
  $self->{'csvFileHandleRaw'} = undef;

  # Finally, re-bless the reference to be of this subclass.
  return bless($self, $class);
}

#
# Public instance methods
#

sub execute($$$) {
  my ($self, $opt, $args) = @_;

  # Get ready to do the work.
  $self->_initialize();

  # Do the work.
  $self->_process();

  # Now that the work is done, clean up after ourselves.
  $self->_cleanUp();
}

sub usage_desc() {
  return USAGE_DESCRIPTION;
}

#
# Private instance methods
#

sub _cleanUp($) {
  my $self = shift();

  close($self->{'csvFileHandleRaw'}) or die("Failed to close " . $self->{'csvFileFullPathRaw'} . ": $!");
  close($self->{'csvFileHandleParsed'}) or die("Failed to close " . $self->{'csvFileFullPathParsed'} . ": $!");
}

sub _downloadAbaChecklist($) {
  my $self = shift();

  # Get the path to the checklist directory including the path of the
  # running script. We do this here because we need the path now for
  # downloading the raw files and later for handling the ZIP archive.
  $self->{'checklistDirFullPathRaw'} = $self->_makeChecklistDirFullPath($self->{'config'}->get('localChecklistSubdirRaw'));

  # Download the raw files and get the full path to the ZIP archive so
  # we can process the contents of the ZIP archive as needed.
  my $csvZipFileFullPath = $self->_downloadAbaChecklistRawFiles($self->{'checklistDirFullPathRaw'});

  # Extract the CSV file from the ZIP archive and return the name of the
  # local, extracted CSV file.
  return $self->_extractCsvFromZipArchive($csvZipFileFullPath);
}

sub _downloadAbaChecklistRawFiles($) {
  my $self = shift();

  my $mechAgent = WWW::Mechanize->new();
  my $response = $mechAgent->get($self->{'config'}->get('abaChecklistUrl'));
  if ($response->is_success) {
    my $content = $response->decoded_content;
  }
  else {
    die($response->status_line);
  }

  my @links = $mechAgent->links();
  if (scalar(@links) == 0) {
    die("Found no links in downloaded web page!");
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
    die("Unable to determine CSV link and/or PDF link.");
  }

  if ($self->{'config'}->get('logLevelDebug')) {
    print("\$csvUrl = [$csvUrl]\n\$pdfUrl = [$pdfUrl]\n");
  }

  # Download the PDF file.
  my $pdfFileFullPath = $self->_saveAbaChecklistFile(
                                                     $mechAgent,
                                                     $pdfUrl,
                                                     $self->{'checklistDirFullPathRaw'}
                                                    );

  # Download the CSV ZIP file.
  my $csvZipFileFullPath = $self->_saveAbaChecklistFile(
                                                        $mechAgent,
                                                        $csvUrl,
                                                        $self->{'checklistDirFullPathRaw'}
                                                       );

  return $csvZipFileFullPath;
}

sub _extractCsvFromZipArchive($$) {
  my (
      $self,
      $csvZipFileFullPath,
     ) = @_;

  # Open the ZIP archive.
  my $zip = Archive::Zip->new();
  unless($zip->read($csvZipFileFullPath) == AZ_OK) {
    die("Unable to read ZIP file [$csvZipFileFullPath]: $!");
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
                                               $self->{'checklistDirFullPathRaw'},
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

sub _initialize($) {
  my $self = shift();

  # Initialize our configuration so we can do our work.
  $self->{'config'} = My::Config->new(runningScriptDirName => $FindBin::Bin);
}

sub _makeChecklistDirFullPath($$) {
  my $self = shift();
  my $checklistSubdir = shift();

  return File::Spec->catfile(
                             $FindBin::Bin,
                             $self->{'config'}->get('localChecklistDir'),
                             $checklistSubdir
                            );
}

sub _makeSymbolicLinkForAbaChecklist($) {
  my $self = shift();

  # Make a symbolic link to the checklist file for easy access later.
  my $linkFilename = File::Spec->catfile(
                                         $self->_makeChecklistDirFullPath($self->{'config'}->get('localChecklistSubdirParsed')),
                                         $self->{'config'}->get('latestChecklistFilename')
                                        );

  if ($self->{'config'}->get('logLevelDebug')) {
    print("Parsed filename = [" . $self->{'csvFileFullPathParsed'} . "]\n");
    print("Linked filename = [$linkFilename]\n");
    print("Before making symbolic link, \$CWD = [$CWD]\n");
  }

  my $dirname = dirname($self->{'csvFileFullPathParsed'});
  my $oldFileBasename = basename($self->{'csvFileFullPathParsed'});
  my $newFileBasename = basename($linkFilename);

  if ($self->{'config'}->get('logLevelDebug')) {
    print("Directory name = [$dirname]\n");
    print("Old file basename = [$oldFileBasename]\n");
    print("New file basename = [$newFileBasename]\n");
  }

  local $CWD = $dirname;

  if (-l $newFileBasename) {
    unlink($newFileBasename) or die("Failed to remove link file [$newFileBasename]: $!");
  }

  symlink($oldFileBasename, $newFileBasename) or die("Failed to link old file [$oldFileBasename] to new file [$newFileBasename]: $!");

  if ($self->{'config'}->get('logLevelDebug')) {
    print("After making symbolic link, \$CWD = [$CWD]\n");
  }
}

sub _openCsvFilesForParsing($) {
  my $self = shift();

  my $outputFileBaseName = basename($self->{'csvFileFullPathRaw'});
  $outputFileBaseName =~ s/\.csv$/.parsed.csv/;
  $self->{'checklistDirFullPathParsed'} = $self->_makeChecklistDirFullPath($self->{'config'}->get('localChecklistSubdirParsed'));

  $self->{'csvFileFullPathParsed'} = File::Spec->catfile(
                                                      $self->{'checklistDirFullPathParsed'},
                                                      $outputFileBaseName
                                                     );

  if ($self->{'config'}->get('logLevelDebug')) {
    print("Input filename  = [" . $self->{'csvFileFullPathRaw'} . "]\n");
    print("Output filename = [" . $self->{'csvFileFullPathParsed'} . "]\n");
  }

  # Open the species input file so we can do our processing.
  open(
       $self->{'csvFileHandleRaw'},
       "< " . ENCODING,
       $self->{'csvFileFullPathRaw'}
      )
    || die("$0: can't open " . $self->{'csvFileFullPathRaw'} . " for reading: $!");

  if ($self->{'config'}->get('logLevelDebug')) {
    print("About to check for output directory [" . $self->{'checklistDirFullPathParsed'} . "]...\n");
  }

  # Create the output directory if it does not already exist.
  if (! -d $self->{'checklistDirFullPathParsed'}) {

    if ($self->{'config'}->get('logLevelDebug')) {
      print("Did not find output directory [" . $self->{'checklistDirFullPathParsed'} . "], attempting to create...\n");
    }

    make_path($self->{'checklistDirFullPathParsed'}) or die("Failed to create output directory [" . $self->{'checklistDirFullPathParsed'} . "]: $!");

    if ($self->{'config'}->get('logLevelDebug')) {
      print("Created output directory [" . $self->{'checklistDirFullPathParsed'} . "].\n");
    }
  }
  else {
    if ($self->{'config'}->get('logLevelDebug')) {
      print("Found output directory [$self->{'checklistDirFullPathParsed'}].\n");
    }
  }

  # Open the species output file so we can do our processing.
  open(
       $self->{'csvFileHandleParsed'},
       "> " . ENCODING,
       $self->{'csvFileFullPathParsed'}
      )
    || die("$0: can't open " . $self->{'csvFileFullPathParsed'} . " for writing: $!");
}

sub _parseAbaChecklist($) {
  my $self = shift();

  my @rows = ();

  # Open the files we will need for the parsing operation.
  $self->_openCsvFilesForParsing();

  # Get ready to operate on the CSV files.
  my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });

  # Process the CSV input file line by line.
  while (my $row = $csv->getline($self->{'csvFileHandleRaw'})) {
    my ($group, $speciesNameEnglish, $speciesNameFrench, $speciesLatinName, $speciesCode, $speciesAbundance) = @$row;

    if ($speciesCode) {
      push(@rows, $row);

      if ($self->{'config'}->get('logLevelTrace')) {
        print("Found species code [$speciesCode] with English species name [$speciesNameEnglish].\n");
      }
    }
  }

  if (scalar(@rows) > 0) {
    # We found at least one row of data, so insert the stock header row
    # into the array as the new first row and write the CSV data to our
    # output file.
    unshift(@rows, $self->{'config'}->get('csvHeaderRow'));
    $csv->say($self->{'csvFileHandleParsed'}, $_) for @rows;
  }
}

sub _process($) {
  my $self = shift();

  if ($self->{'config'}->get('abaChecklistDownloadEnabled')) {
    # Download the checklist file from the official source.
    $self->{'csvFileFullPathRaw'} = $self->_downloadAbaChecklist();
  }
  else {
    # In lieu of downloading, just point to a local file already in place.
    $self->{'csvFileFullPathRaw'} = File::Spec->catfile(
                                                makeChecklistDirFullPath($self->{'config'}->get('localChecklistSubdirRaw')),
                                                $self->{'config'}->get('downloadedRawTestFilename')
                                               );
  }

  # Do the local parsing to get the checklist file ready for searching.
  $self->_parseAbaChecklist();

  # Create a symbolic link to the parsed checklist file for later
  # searching.
  $self->_makeSymbolicLinkForAbaChecklist();
}

sub _saveAbaChecklistFile($$$) {
  my ($self, $mechAgent, $sourceUrl) = @_;

  my $response = $mechAgent->get($sourceUrl);
  if (! $response->is_success) {
    die($response->status_line);
  }

  # Save the file locally.
  my $localFileFullPath = File::Spec->catfile(
                                              $self->{'checklistDirFullPathRaw'},
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

1;

# End of module
