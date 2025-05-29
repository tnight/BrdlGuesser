package BrdlGuesser::Command::dump;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;

#
# Public instance methods
#

sub abstract {
  return "display all of the possible BRDL answers";
}

sub description {
  return "display every possible BRDL answer, which is a long list of over a thousand species.";
}

#
# Private instance methods
#

sub _initialize() {
  my $self = shift();

  # Call our superclass method so it can do the necessary initialization.
  $self->SUPER::_initialize();

  # Do the further initialization that our subclass needs.
  $self->{'searchPattern'} = '[A-Z]{4}';
}

1;

# end of module
