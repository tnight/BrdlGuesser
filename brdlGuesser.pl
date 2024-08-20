#!/usr/bin/perl -w

use strict;

sub main() {

  my $argCount = scalar(@ARGV);
  my $encoding = ":encoding(UTF-8)";
  my $fileHandle = undef;
  my $matchCount = 0;
  my $pattern = '\w{4}';
  my $speciesFilename = 'ABA_Checklist-8.15.csv';  # The full data file.
  # my $speciesFilename = 'short.csv';  # A small data file for testing.
  my $usage = <<END;
usage: $0 [pattern]

Search for a four-letter Alpha code using a regular expression search pattern.
If no pattern is supplied, all four-letter Alpha codes will match.

Example: $0 'R\\wBU'
END

  if ($argCount != 0 && $argCount != 1) {
    print STDERR "$usage\n";
    exit 1;
  }
  elsif ($argCount == 1) {
    $pattern = $ARGV[0];
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

    # Search for a match with our pattern.
    if (m#,($pattern),\d+$#) {
      # Our pattern matched, so output the result.
      printf("%4d. %s\n", ++$matchCount, $1);
    }
  }
  if ($!) {
    die("$0: unexpected error while reading from $speciesFilename: $!");
  }

  return $matchCount > 0 ? 0 : 1;
}

exit main();

# End of script.
