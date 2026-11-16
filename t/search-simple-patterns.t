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
use Test::More tests => 10;  # The number of tests we will run in this file.

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
my $result;

# Do a search looking for a simple, exact match.
$result = test_app($brdlGuesser => [qw(search -p rwbl)]);

# Assert that the right things happened.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');
like($result->stdout, qr/RWBL/, 'printed the search result that we expected');

# Do another search looking for a simple wildcard match.
$result = test_app($brdlGuesser => [qw(search -p rwb_)]);

#
# Assert that the right things happened.
#

# No signs of an error condition.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');

# We assert that the output has a reasonable number of lines.
my $lineCount = ($result->output =~ tr/\n//);
cmp_ok($lineCount, '==', 2, 'output has exactly 2 lines');

# We find the expected species code in the output.
like($result->stdout, qr/RWBL/, 'printed the first search result that we expected');
like($result->stdout, qr/RWBU/, 'printed the second search result that we expected');

# TODOTODO: Add more tests.

# End of test script.
