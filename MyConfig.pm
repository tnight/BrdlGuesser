package MyConfig;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use AppConfig qw( :argcount );
use File::Basename;

# Define the constant we will use to open our config file.
use constant CONFIG_FILENAME => 'myConfig.cfg';

#
# Constructors
#

sub new() {
  my $class = shift();
  my $self = bless(
                   { _appConfig => _initializeConfig() },
                   $class
                  );
  return $self;
}

#
# Public instance methods
#

sub get() {
  my $self = shift();
  my $attribute = shift();

  return $self->{_appConfig}->get($attribute);
}

#
# Private instance methods
#
sub _initializeConfig() {
  # Define the configuration and the variables we will store there.
  my $config = AppConfig->new({ CASE => 1, ERROR => \&handleConfigError, PEDANTIC => 1 });
  $config->define('abaChecklistUrl', { ARGCOUNT => ARGCOUNT_ONE });
  $config->define('abaChecklistDownloadEnabled', { ARGCOUNT => ARGCOUNT_NONE, DEFAULT => '<undef>' });
  $config->define('csvHeaderRow', { ARGCOUNT => ARGCOUNT_LIST } );
  $config->define('downloadedRawTestFilename', { ARGCOUNT => ARGCOUNT_ONE });
  $config->define('latestChecklistFilename', { ARGCOUNT => ARGCOUNT_ONE });
  $config->define('localChecklistDir', { ARGCOUNT => ARGCOUNT_ONE });
  $config->define('localChecklistSubdirParsed', { ARGCOUNT => ARGCOUNT_ONE });
  $config->define('localChecklistSubdirRaw', { ARGCOUNT => ARGCOUNT_ONE });
  $config->define('logLevelDebug', { ARGCOUNT => ARGCOUNT_NONE, DEFAULT => '<undef>' });
  $config->define('logLevelTrace', { ARGCOUNT => ARGCOUNT_NONE, DEFAULT => '<undef>' });

  # Read the configuration values from our configuration file.
  my $configFileFullPath = File::Spec->catfile(
                                               dirname(__FILE__),
                                               CONFIG_FILENAME
                                              );
  $config->file($configFileFullPath);

  # Log the contents of our configuration.
  if ($config->get('logLevelTrace')) {
    print("Full dump of our configuration:\n", Data::Dumper->Dump([$config], [qw(config)]));
  }

  return $config;
}

sub handleConfigError() {
  die(@_);
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module.
