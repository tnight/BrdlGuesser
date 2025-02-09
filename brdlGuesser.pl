#!/usr/bin/perl -w

# Gain access to all the pragmas and modules we'll need.
use strict;
use File::Basename;
use File::Spec;
use Getopt::Long;
use List::Util qw( all );

# Make a forward declaration of our subroutines.
sub main();
sub getStringAsArray($);
sub validateOptions();
sub validateListsAsMutuallyExclusive($$$);

# Define constants we need.
$::USAGE = <<END;
usage: $0 [-d|--dump] [-h|--help] [-i|--include letters] [-p|--pattern search-pattern] [-x|--exclude letters]

Search for a four-letter Alpha code using a regular expression search pattern.
One of the -d, -p, or -x options is required. If -p is given, it overrides any
-d option.

EXAMPLES
shell> $0 -p 'R*BU'
shell> $0 -p '*ar*'
shell> $0 -p 'G*A*' -x bmos
shell> $0 -p 'G*A*' -i tw

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
* To prevent the shell from interpreting any asterisks in your pattern, enclose the pattern with single quotes.
END

# Call the main subroutine, returning its return value to our caller.
exit main();

sub main() {
  my $encoding = ":encoding(UTF-8)";
  my $exclusionRegex = undef;
  my $fileHandle = undef;
  my @inclusionRegexen = ();
  my $matchCount = 0;
  my $searchPattern = undef;
  my $speciesFilename = 'ABA_Checklist-8.17.csv';  # The full data file.
  # my $speciesFilename = 'short.csv';  # A small data file for testing.
  # my $speciesFilename = 'less-short.csv';  # A larger data file for testing.

  # NOTE: the data file must have Unix-style line endings, not DOS or Mac.

  # Get and validate our command-line options.
  my $opts = validateOptions();

  # Get the path to the input file including the path of the running script.
  my $speciesPath = File::Spec->catfile(
					dirname(__FILE__),
					$speciesFilename
				       );

  # Configure the search pattern based on our command-line options.
  if (exists $opts->{'pattern'}) {
    $searchPattern = uc($opts->{'pattern'});
    $searchPattern =~ s#\*#[A-Z]#g;
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

  SPECIES: while (<$fileHandle>) {
    # Remove the newline for more convenient processing and printing.
    chomp();

    # Search for a match with our search pattern.
    if (m#^,(".+"+?|[^,]+?),.+,($searchPattern),\d+$#) {
      my ($speciesName, $speciesCode) = ($1, $2);

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

      # Strip out the quotes because we do not want those in our output.
      $speciesName =~ tr/"//d;

      # Our pattern matched, so output the result.
      printf(
	     "%4d. %s: %s\n",
	     ++$matchCount,
	     $speciesCode,
	     $speciesName
	    );
    }
  }
  if ($!) {
    die("$0: unexpected error while reading from $speciesPath: $!");
  }

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
  die($::USAGE) if (
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
      die("Search pattern [$opts->{'pattern'}] does not have exactly four characters.\n$::USAGE");
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
  my $inclusionStringNoStars = uc($inclusionString);
  $inclusionStringNoStars =~ s/\Q*\E//g;

  foreach my $inclusionLetter (getStringAsArray($inclusionStringNoStars)) {

    if ($exclusionStringUppercase =~ m/$inclusionLetter/) {
      die(
	  "Letter appears both in exclusion list and " .
	  "$inclusionFieldDisplayName: " .
	  $inclusionLetter .
	  "\n" .
	  $::USAGE
	 );
    }
  }
}

# End of script.
