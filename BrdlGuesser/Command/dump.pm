package BrdlGuesser::Command::dump;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;

sub execute {
  my ($self, $opt, $args) = @_;

  # Trying out a superclass method.
  # TODOTODO: Remove after testing.
  $self->_helloWorld();

  print "Would have executed the dump command here...\n";
}

1;

# end of module
