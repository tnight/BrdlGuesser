#!/usr/bin/perl -w

use strict;

sub main() {

  my $argCount = scalar(@ARGV);
  my $encoding = ":encoding(UTF-8)";
  my $fileHandle = undef;
  my $matchCount = 0;
  my $pattern = '\w{4}';
  # my $speciesFilename = 'ABA_Checklist-8.15.csv';
  my $speciesFilename = 'short.csv';
  my $usage = "usage: $0 [pattern]";

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
    || die "$0: can't open $speciesFilename for reading: $!";

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
    die "$0: unexpected error while reading from $speciesFilename: $!";
  }



  # More sophisticated example:

  # perl -ne 'if (m#,(R\wBU),\d+$#) { printf "%4d. %s\n", ++$count, $1; }' ABA_Checklist-8.15.csv


}

main();

# End of script.
