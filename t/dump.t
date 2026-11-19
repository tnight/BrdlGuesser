#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Pull in our local helper.
use lib 't/lib';
use TestHelper;

# Get ready for testing in general.
use Test::More tests => 5;  # The number of tests we will run in this file.

# Get ready for App::Cmd testing in particular.
use App::Cmd::Tester;

# Gain access to our application module.
use App::BrdlGuesser;

# Instantiate our application instance.
my $brdlGuesser = TestHelper->setup();

# Run the application.
my $result = test_app($brdlGuesser => [qw(dump)]);

#
# Assert that the right things happened.
#

# No signs of an error condition.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');

# We assert that the output has a reasonable number of lines.
my $lineCount = ($result->output =~ tr/\n//);
cmp_ok($lineCount, '>=', 1000, 'output has at least 1,000 lines');

# We find an expected species code in the output.
like($result->stdout, qr/ROPI/, 'printed the dump that we expected');

# End of test script.
