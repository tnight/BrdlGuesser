#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use lib dirname (__FILE__);

use BrdlGuesser;

# Set the option that causes the version command to be shown as part of
# the help message.
my $brdlGuesser = BrdlGuesser->new({ 'show_version_cmd' => 1 });

# Run the application.
$brdlGuesser->run();

# End of script
