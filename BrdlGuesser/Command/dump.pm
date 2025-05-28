package BrdlGuesser::Command::dump;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;

#
# Public instance methods
#

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
  my $matchCount = $self->_searchFile();

  # Return the result code for our search.
  return $matchCount > 0 ? 0 : 1;
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error("No args allowed") if @$args;
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
