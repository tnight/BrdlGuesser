package BrdlGuesser::Command;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use App::Cmd::Setup -command;

# TODOTODO: Place common code into this superclass because both the
# "dump" and "search" commands do much of the same work.

# Trying out a superclass method.
# TODOTODO: Remove after testing.
sub _helloWorld() {
  print("Hello, world!\n");
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module
