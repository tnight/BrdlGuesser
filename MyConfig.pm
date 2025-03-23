# Gain access to all the pragmas and modules we'll need.
use v5.38;
use strict;
use warnings;
use AppConfig;
use File::Basename;

# These must come last to prevent spurious warning messages.
use feature qw(class);
no warnings qw(experimental);

class MyConfig 1.0 {
  # Define the constant we will use to open our config file.
  use constant CONFIG_FILENAME => 'myConfig.cfg';

  #
  # Field attributes
  #

  field $appConfig;

  #
  # Phasers
  #

  ADJUST {
    $appConfig = $self->_initializeConfig();
  }

  #
  # Public instance methods
  #

  method get($attribute) {
    return $appConfig->get($attribute);
  }

  #
  # Private instance methods
  #

  method _initializeConfig() {
    # Define the configuration and the variables we will store there.
    my $config = AppConfig->new({ CASE => 1, ERROR => \&_handleConfigError, PEDANTIC => 1 });
    $config->define('abaChecklistUrl', { ARGCOUNT => AppConfig::ARGCOUNT_ONE });
    $config->define('abaChecklistDownloadEnabled', { ARGCOUNT => AppConfig::ARGCOUNT_NONE, DEFAULT => '<undef>' });
    $config->define('csvHeaderRow', { ARGCOUNT => AppConfig::ARGCOUNT_LIST } );
    $config->define('downloadedRawTestFilename', { ARGCOUNT => AppConfig::ARGCOUNT_ONE });
    $config->define('latestChecklistFilename', { ARGCOUNT => AppConfig::ARGCOUNT_ONE });
    $config->define('localChecklistDir', { ARGCOUNT => AppConfig::ARGCOUNT_ONE });
    $config->define('localChecklistSubdirParsed', { ARGCOUNT => AppConfig::ARGCOUNT_ONE });
    $config->define('localChecklistSubdirRaw', { ARGCOUNT => AppConfig::ARGCOUNT_ONE });
    $config->define('logLevelDebug', { ARGCOUNT => AppConfig::ARGCOUNT_NONE, DEFAULT => '<undef>' });
    $config->define('logLevelTrace', { ARGCOUNT => AppConfig::ARGCOUNT_NONE, DEFAULT => '<undef>' });

    # Read the configuration values from our configuration file.
    my $configFileFullPath = File::Spec->catfile(
                                                 File::Basename::dirname(__FILE__),
                                                 CONFIG_FILENAME
                                                );
    $config->file($configFileFullPath);

    # Log the contents of our configuration.
    if ($config->get('logLevelTrace')) {
      print("Full dump of our configuration:\n", Data::Dumper->Dump([$config], [qw(config)]));
    }

    return $config;
  }

  #
  # As an error handler, this subroutine needs to be declared in the old Perl style.
  #

  sub _handleConfigError ($) {
    die(@_);
  }
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module.
