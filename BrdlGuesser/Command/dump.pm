package BrdlGuesser::Command::dump;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;

# Define our usage message as a constant.
use constant USAGE_DESCRIPTION => <<END;
%c dump %o

This command will display every possible BRDL answer, which is a long
list of over a thousand species.
END

#
# Public instance methods
#

sub abstract() {
  return "display all of the possible BRDL answers";
}

sub usage_desc() {
  return USAGE_DESCRIPTION;
}

1;

# end of module
