#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Pull in our local helper.
use lib 't/lib';
use TestHelper;

# Get ready for testing in general.
use Test::More tests => 6;

# Get ready for App::Cmd testing in particular.
use App::Cmd::Tester;

# Instantiate our application instance.
my $brdlGuesser = TestHelper->setup();

# Assert that we successfully instantiated the app.
ok(defined($brdlGuesser));
ok($brdlGuesser->isa('App::BrdlGuesser'));

# Run the application.
my $result = test_app($brdlGuesser => []);

# Assert that the right things happened.
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'numeric exit code is zero');
is($result->stderr, '', 'nothing sent to stderr');
like($result->stdout, qr/commands/, 'Usage message sent to stdout');

# End of test script.
