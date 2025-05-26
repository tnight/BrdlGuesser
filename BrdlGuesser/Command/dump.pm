package BrdlGuesser::Command::dump;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;

sub abstract {
  return "display all of the possible BRDL answers.";
}

sub description {
  return "display every possible BRDL answer, which is a long list of over a thousand species.";
}

sub execute {
  my ($self, $opt, $args) = @_;

  # Get ready to do the work.
  $self->_initialize();

  # Do the work.
  # TODOTODO: Actually do the work instead of just saying we would have done it.
  print "Would have executed the dump command here...\n";
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error("No args allowed") if @$args;
}

1;

# end of module
