#!/usr/bin/perl -w

# Gain access to all the pragmas and modules we'll need.
use strict;
use Getopt::Long;

# Forward-declare our subroutines.
sub main();
sub validateOptions($);

# Define constants we need.
$::USAGE = <<END;
usage: $0 [-h|--help] [-p|--pattern search-pattern] [-x|--exclude letters]

Search for a four-letter Alpha code using a regular expression search pattern.
If no pattern is supplied, all four-letter Alpha codes will match.

EXAMPLES
shell> $0 -p R*BU
shell> $0 -p *AR*
shell> $0 -p G*A* -x BMOS

OPTIONS

-h | --help: Display this usage message.
-p | --pattern: Search for the given pattern.
-x | --exclude: Exclude guesses that contain any of the given letters.
END

# Call the main subroutine, returning its return value to our caller.
exit main();

sub main() {
  my $encoding = ":encoding(UTF-8)";
  my $exclusionRegex = undef;
  my $fileHandle = undef;
  my $matchCount = 0;
  my $searchPattern = undef;
  my $speciesFilename = 'ABA_Checklist-8.15.csv';  # The full data file.
  # my $speciesFilename = 'short.csv';  # A small data file for testing.
  # my $speciesFilename = 'less-short.csv';  # A larger data file for testing.

  # Get and validate our command-line options.
  my $opts = validateOptions($::USAGE);

  # Configure the search pattern based on our command-line options.
  if (exists $opts->{'pattern'}) {
    $searchPattern = $opts->{'pattern'};
    $searchPattern =~ s#\*#[A-Z]#g;
  }
  else {
    $searchPattern = '[A-Z]{4}';
  }

  # Configure the exclusion pattern based on our command-line options.
  if (exists $opts->{'exclude'}) {
    my $exclusionPattern = '[' . $opts->{'exclude'} . ']';
    $exclusionRegex = qr/$exclusionPattern/;
  }

  open(
       $fileHandle,
       "< $encoding",
       $speciesFilename
      )
    || die("$0: can't open $speciesFilename for reading: $!");

  while (<$fileHandle>) {
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

	next;
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
    die("$0: unexpected error while reading from $speciesFilename: $!");
  }

  return $matchCount > 0 ? 0 : 1;
}

sub validateOptions($) {
  my $usage = shift();
  my $opts = {};

  my $optsOk = GetOptions(
			  $opts,
			  'exclude|x=s',
			  'pattern|p=s',
			  'help|h'
			 );

  die($usage) if (! $optsOk || exists($opts->{'help'}));

  return $opts;
}

# End of script.
