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
use Test::More tests => 4;  # The number of tests we will run in this file.

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

# Run the application.
my $result = test_app($brdlGuesser => [qw(--version)]);

#
# Assert that the right things happened.
#

# No signs of an error condition.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');

# We find an expected species code in the output.
my $versionNumber = $brdlGuesser->VERSION;
like($result->stdout, qr/$versionNumber/, 'printed the version number that we expected');

# End of test script.
