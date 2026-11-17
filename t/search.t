#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use File::Spec;
my $runningScriptDirName;
BEGIN {
  $runningScriptDirName = File::Spec->catfile(
    dirname(__FILE__),
    '..'
  );
}
use lib $runningScriptDirName;
chdir $runningScriptDirName or die "Cannot chdir to project root [$runningScriptDirName]: $!";

# Get ready for testing in general.
use Test::More tests => 25;  # The number of tests we will run in this file.

# Get ready for App::Cmd testing in particular.
use App::Cmd::Tester;

# Gain access to our application module.
use BrdlGuesser;

# Instantiate our application instance.
my $brdlGuesser = BrdlGuesser->new(
                                   {
                                    'runningScriptDirName' => $runningScriptDirName,
                                    'show_version_cmd' => 1
                                   }
                                  );

# Declare some local variables that we will reuse.
my ($lineCount, $matchCount, @optionNames, @optionValues, $result);

#
# Do a search looking for a simple, exact match.
#
$result = test_app($brdlGuesser => [qw(search -p rwbl)]);

# Assert that the right things happened.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');
like($result->stdout, qr/RWBL/, 'printed the search result that we expected');

#
# Do another search looking for a simple wildcard match.
#
$result = test_app($brdlGuesser => [qw(search -p rwb_)]);

# No signs of an error condition.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');

# We assert that the output has a reasonable number of lines.
$lineCount = ($result->output =~ tr/\n//);
cmp_ok($lineCount, '==', 2, 'output has exactly two lines');

# We find the expected species code in the output.
like($result->stdout, qr/RWBL/, 'printed the first search result that we expected');
like($result->stdout, qr/RWBU/, 'printed the second search result that we expected');

#
# Do another search using a combination of exclusion list, inclusion list, and pattern.
#
@optionNames = ('i', 'p', 'x');
@optionValues = ('b:2', '__BI', 'waef');
$result = test_app($brdlGuesser =>
                   [
                    'search',
                    "-$optionNames[0]", $optionValues[0],
                    "-$optionNames[1]", $optionValues[1],
                    "-$optionNames[2]", $optionValues[2]
                   ]
                  );

# No signs of an error condition.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');

# We assert that the output has a reasonable number of lines.
$lineCount = ($result->output =~ tr/\n//);
cmp_ok($lineCount, '>=', 5, 'output has five or more lines');
cmp_ok($lineCount, '<=', 10, 'output has ten or fewer lines');

# We find the expected species code in the output.
like($result->stdout, qr/LIBI/, 'printed the first search result that we expected');
like($result->stdout, qr/YCBI/, 'printed the second search result that we expected');

#
# Do a search like the one explained in my Notes app when the solution is REEG (Reddish Egret).
#
@optionNames = ('i');
@optionValues = ('e:14:2');
$result = test_app($brdlGuesser =>
                   [
                    'search',
                    "-$optionNames[0]", $optionValues[0]
                   ]
                  );

# No signs of an error condition.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');

# We assert that the output has a reasonable number of lines.
cmp_ok($lineCount, '>=', 5, 'output has five or more lines');
cmp_ok($lineCount, '<=', 300, 'output has 300 or fewer lines');
### cmp_ok($lineCount, '<=', 10, 'output has ten or fewer lines');

my @lines = split(/\R/, $result->stdout);
$lineCount = scalar(@lines);

# We assert that the output has a reasonable number of lines.
cmp_ok($lineCount, '>=', 5, 'output has five or more lines');
cmp_ok($lineCount, '<=', 10, 'output has ten or fewer lines');

# We verify that each species code in the output matches the pattern '_EE_'.
subtest 'Every line of output matches expected format' => sub {
  plan tests => $lineCount;

  my $regex = qr/^\s+\d+\.\s+\wE{2}\w:/;
  for my $i (0 .. $lineCount) {
    if (defined($lines[$i])) {
      like($lines[$i], $regex, "Line " . ($i + 1) . " matches");
    }
  }
};

# End of test script.
