#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use lib dirname (__FILE__);

use AbaChecklistFetcher::Cmd;

# Set the option that causes the version command to be shown as part of
# the help message.
my $abaChecklistFetcher = AbaChecklistFetcher::Cmd->new({ 'show_version_cmd' => 1 });

# Run the application and return the result to our caller.
exit($abaChecklistFetcher->run());

# End of script
