#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use File::Spec;
use lib File::Spec->catfile(
                            dirname(__FILE__),
                            '..'
                           );

# Get ready for testing.
use Test::More tests => 2;

# Gain access to our application module.
use BrdlGuesser;

# Instantiate our application instance.
my $brdlGuesser = BrdlGuesser->new({ 'show_version_cmd' => 1 });

# TODOTODO: Look into using App::Cmd::Tester or Test::Script.

# Run the application.
$brdlGuesser->run();

# Assert that the right things happened.
ok(defined($brdlGuesser));
ok($brdlGuesser->isa('BrdlGuesser'));

# TODOTODO: Assert that the correct output was generated.

# End of test script.
