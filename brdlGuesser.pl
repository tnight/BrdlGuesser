#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use lib dirname (__FILE__);

# Gain access to our application module.
use BrdlGuesser;

# Gain access to our logging module. The default level is WARN.
use Log::Any::App '$log';

# Set the option that causes the version command to be shown as part of
# the help message.
my $brdlGuesser = BrdlGuesser->new({ 'show_version_cmd' => 1 });

# Run the application and return the result to our caller.
exit($brdlGuesser->run());

# End of script
