# This class uses the "new" (as of 2025) Corinna framework, which
# defines the "class" keyword. More information can be found here:
# https://dev.to/ovid/bringing-modern-oo-to-perl-51ak

# Gain access to all the pragmas and modules we'll need.
use v5.38;
use strict;
use warnings;
use AppConfig;
use Data::Dumper;
use File::Basename;
use File::Spec;

# These must come last to prevent spurious warning messages.
use feature qw(class);
no warnings qw(experimental);

class My::Config 2.0 {
  # Define the constants we will use to open our config file.
  use constant CONFIG_DIRECTORY => 'config';
  use constant CONFIG_FILENAME => 'myConfig.cfg';

  # This is inside the class to prevent spurious warning messages.
  use Log::Any qw($log);

  #
  # Field attributes
  #

  field $appConfig;
  field $configFileFullPath;
  field $runningScriptDirName :param;

  #
  # Phasers
  #

  ADJUST {
    $configFileFullPath = $self->_calcConfigFileFullPath($runningScriptDirName);
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

  method _calcConfigFileFullPath($runningScriptDirName) {
    $configFileFullPath = File::Spec->catfile(
                                              $runningScriptDirName,
                                              CONFIG_DIRECTORY,
                                              CONFIG_FILENAME
                                             );
  }

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

    # Read the configuration values from our configuration file.
    $config->file($configFileFullPath);

    # Log the contents of our configuration, but only bother serializing
    # them if our log level requires it.
    if ($log->is_trace) {
      $log->trace("Full dump of our configuration:\n", Data::Dumper->Dump([$config], [qw(config)]));
    }

    return $config;
  }

  #
  # As an error handler, this subroutine needs to be declared in the old Perl style.
  #

  sub _handleConfigError ($) {
    die($log->fatal(@_));
  }
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module.
