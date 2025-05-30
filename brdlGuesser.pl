#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use lib dirname(__FILE__);

# Gain access to all the other modules we'll need.
use File::Spec;
use Getopt::Long;
use My::Config;
use Text::CSV;

# Define our usage message as a constant.
use constant USAGE => <<END;
usage: $0 [-d|--dump] [-h|--help] [-i|--include letters] [-p|--pattern search-pattern] [-x|--exclude letters]

Search for a four-letter Alpha code using a search pattern. To represent
an unknown letter, use the underscore ('_').
One of the -d, -p, or -x options is required. If -p is given, it
overrides any -d option.

EXAMPLES
shell> $0 -p R_BU
shell> $0 -p _ar_
shell> $0 -p G_A_ -x bmos
shell> $0 -p G_A_ -i tw

OPTIONS
-d | --dump: Display all of the possible BRDL answers.
-h | --help: Display this usage message.
-i | --include: Only include guesses that contain all of the given letters.
-p | --pattern: Search for the given pattern.
-x | --exclude: Exclude guesses that contain any of the given letters.

NOTES
* Both the search pattern and the letters to be included and excluded can
be given as uppercase or lowercase, and will still match.
* The same letter cannot appear in both the exclusion and inclusion lists.
END

# Declare our configuration, which will be visible to all of our
# subroutines.
our $config = undef;

# Make a forward declaration of our subroutines.
sub main();
sub getStringAsArray($);
sub validateOptions();
sub validateListsAsMutuallyExclusive($$$);

# Call the main subroutine, returning its return value to our caller.
exit main();

sub main() {
  my $encoding = ":encoding(UTF-8)";
  my $exclusionRegex = undef;
  my $fileHandle = undef;
  my @inclusionRegexen = ();
  my $matchCount = 0;
  my $searchPattern = undef;

  # Initialize our configuration so we can do our work.
  $config = My::Config->new(runningScriptDirName => dirname(__FILE__));

  # Choose from among the available species files.
  #
  # NOTE: The data file must have Unix-style line endings, not DOS or Mac.
  my $speciesFilename = $config->get('latestChecklistFilename'); # Latest full data file.
  # my $speciesFilename = 'short.csv';  # Small data file for testing.
  # my $speciesFilename = 'less-short.csv';  # Larger data file for testing.

  # Get and validate our command-line options.
  my $opts = validateOptions();

  # Get the path to the input file including the path of the running script.
  my $speciesPath = File::Spec->catfile(
                                        $config->get('localChecklistDir'),
                                        $config->get('localChecklistSubdirParsed'),
                                        $speciesFilename
                                       );

  # Configure the search pattern based on our command-line options.
  if (exists $opts->{'pattern'}) {
    $searchPattern = uc($opts->{'pattern'});
    $searchPattern =~ s#_#[A-Z]#g;
  }
  else {
    $searchPattern = '[A-Z]{4}';
  }

  # Configure the exclusion pattern based on our command-line options.
  if (exists $opts->{'exclude'}) {
    my $exclusionPattern = '[' . uc($opts->{'exclude'}) . ']';
    $exclusionRegex = qr/$exclusionPattern/;
  }

  # Configure the inclusion patterns based on our command-line options.
  if (exists $opts->{'include'}) {
    foreach my $inclusionLetter (getStringAsArray($opts->{'include'})) {
      push(@inclusionRegexen, qr/$inclusionLetter/);
    }
  }

  # Open the species input file so we can do our processing.
  open(
       $fileHandle,
       "< $encoding",
       $speciesPath
      )
    || die("$0: can't open $speciesPath for reading: $!");

  # Get ready to parse the CSV file.
  my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });

SPECIES:
  while (my $row = $csv->getline($fileHandle)) {
    my ($group, $speciesNameEnglish, $speciesNameFrench, $speciesLatinName, $speciesCode, $speciesAbundance) = @$row;

    # Search for a match with our search pattern.
    if ($speciesCode =~ m/^$searchPattern$/) {
      # Exclude species codes containing the letters we were told to exclude.
      if (
          defined($exclusionRegex) &&
          $speciesCode =~ $exclusionRegex
         ) {

        next SPECIES;
      }

      # Only include species codes containing all the letters we were
      # told to include.
      if (scalar(@inclusionRegexen)) {
        foreach my $inclusionRegex (@inclusionRegexen) {
          if ($speciesCode !~ $inclusionRegex) {
            next SPECIES;
          }
        }
      }

      # Our pattern matched, so output the result.
      printf(
             "%4d. %s: %s\n",
             ++$matchCount,
             $speciesCode,
             $speciesNameEnglish
            );
    }
  }
  if ($!) {
    die("$0: unexpected error while reading from $speciesPath: $!");
  }

  close($fileHandle) or die("Failed to close $speciesPath: $!");

  return $matchCount > 0 ? 0 : 1;
}

sub getStringAsArray($) {
  my $inclusionString = shift();

  return split(
               //,
               uc($inclusionString)
              );
}

sub validateOptions() {
  my $opts = {};

  my $optsOk = GetOptions(
                          $opts,
                          'dump|d',
                          'help|h',
                          'exclude|x=s',
                          'include|i=s',
                          'pattern|p=s'
                         );

  # Make sure at least one required option was specified.
  die(USAGE) if (
                  ! $optsOk ||
                  exists($opts->{'help'}) ||
                  (
                   ! exists($opts->{'dump'}) &&
                   ! exists($opts->{'exclude'}) &&
                   ! exists($opts->{'include'}) &&
                   ! exists($opts->{'pattern'})
                  )
                 );

  # Validate that the search pattern has exactly four characters.
  if (
      exists($opts->{'pattern'}) &&
      length($opts->{'pattern'}) != 4
     )
    {
      die("Search pattern [$opts->{'pattern'}] does not have exactly four characters.\nUSAGE");
    }

  # Validate that the search pattern contains no invalid characters.
  if (
      exists($opts->{'pattern'}) &&
      $opts->{'pattern'} =~ m/[^_[:alpha:]]/
     )
    {
      die("Search pattern [$opts->{'pattern'}] contains one or more invalid characters. Only letters and underscores are allowed.\nUSAGE");
    }

  # Validate that no letter appears in both the exclusion and inclusion
  # lists.
  if (
      exists($opts->{'exclude'}) &&
      exists($opts->{'include'})
     )
  {
    validateListsAsMutuallyExclusive(
                                     $opts->{'exclude'},
                                     $opts->{'include'},
                                     'inclusion list'
                                    );
  }

  # Validate that no letter appears in both the exclusion list and the
  # search pattern.
  if (
      exists($opts->{'exclude'}) &&
      exists($opts->{'pattern'})
     )
  {
    validateListsAsMutuallyExclusive(
                                     $opts->{'exclude'},
                                     $opts->{'pattern'},
                                     'search pattern'
                                    );
  }

  return $opts;
}

sub validateListsAsMutuallyExclusive($$$) {
  my $exclusionString = shift;
  my $inclusionString = shift;
  my $inclusionFieldDisplayName = shift;

  my $exclusionStringUppercase = uc($exclusionString);
  my $inclusionStringNoUnderscores = uc($inclusionString);
  $inclusionStringNoUnderscores =~ s/\Q_\E//g;

  foreach my $inclusionLetter (getStringAsArray($inclusionStringNoUnderscores)) {

    if ($exclusionStringUppercase =~ m/$inclusionLetter/) {
      die(
          "Letter appears both in exclusion list and " .
          "$inclusionFieldDisplayName: " .
          $inclusionLetter .
          "\n" .
          USAGE
         );
    }
  }
}

# End of script.
