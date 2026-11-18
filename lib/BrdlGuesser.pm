package BrdlGuesser;

use strict;
use warnings;
use App::Cmd::Setup -app;
use File::Basename;
use File::Spec;
use FindBin;

# Expose our application version for use by the "version" command.
use constant VERSION => 1.06;

# Constructor
sub new {
  my ($class, $args) = @_;
  $args ||= {};
  
  # Call the parent App::Cmd constructor.
  my $self = $class->SUPER::new($args);

  # Initialize our configuration.
  $self->config(My::Config->new());

  # Return our newly-created app instance.
  return $self;
}

# Accessor for getting and setting our configuration.
sub config {
  my ($self, $newValue) = @_;

  if (@_ > 1) {
    $self->{'config'} = $newValue;
  }

  return $self->{'config'};
}

1;

# End of module
