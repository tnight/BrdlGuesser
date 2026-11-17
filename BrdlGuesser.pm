package BrdlGuesser;

use strict;
use warnings;
use App::Cmd::Setup -app;
use FindBin;

# Expose our application version for use by the "version" command.
use constant VERSION => 1.06;

# Constructor
sub new {
  my ($class, $args) = @_;
  $args ||= {};

  # Extract and delete our custom argument before SUPER::new sees it.
  my $runningScriptDirName = delete($args->{'runningScriptDirName'});

  # Call the parent App::Cmd constructor.
  my $self = $class->SUPER::new($args);

  # Store the argument value as part of the app instance.
  $self->runningScriptDirName($runningScriptDirName || $FindBin::Bin);

  # Initialize our configuration.
  $self->config(My::Config->new(runningScriptDirName => $self->runningScriptDirName()));

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

# Accessor for getting and setting our running script directory name.
sub runningScriptDirName {
  my ($self, $newValue) = @_;

  if (@_ > 1) {
    $self->{'runningScriptDirName'} = $newValue;
  }

  return $self->{'runningScriptDirName'};
}

1;

# End of module
