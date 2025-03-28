#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use lib dirname (__FILE__);

use BrdlGuesser;

BrdlGuesser->run();

# End of script
