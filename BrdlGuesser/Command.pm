# I tried using the "new" (as of 2025) Corinna framework for this class,
# but the App::Cmd framework complained that the class hierarchy was not
# as it expects. Maybe someday the different frameworks will work
# together? Until then, we have to use the old school Perl OO syntax.
#
# More information about Corinna can be found here:
# https://dev.to/ovid/bringing-modern-oo-to-perl-51ak

package BrdlGuesser::Command;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use App::Cmd::Setup -command;
use File::Basename;
use FindBin;
use My::Config;
use Text::CSV;

#
# Constructor
#

sub new {
  my ($class, $arg) = @_;

  # First, call the constructor of our superclass.
  my $self = $class->SUPER::new($arg);

  # Then, initialize the parts of the object that are unique to this class.
  $self->{'config'} = undef;
  $self->{'csv'} = undef;
  $self->{'encoding'} = ":encoding(UTF-8)";
  $self->{'fileHandle'} = undef;

  # Finally, re-bless to our class.
  return bless($self, $class);
}

#
# Private instance methods
#

sub _initialize() {
  my $self = shift();

  # Initialize our configuration so we can do our work.
  $self->{'config'} = My::Config->new(runningScriptDirName => $FindBin::Bin);

  # Choose from among the available species files.
  #
  # NOTE: The data file must have Unix-style line endings, not DOS or Mac.
  my $speciesFilename = $self->{'config'}->get('latestChecklistFilename'); # Latest full data file.
  # my $speciesFilename = 'short.csv';  # Small data file for testing.
  # my $speciesFilename = 'less-short.csv';  # Larger data file for testing.

  # Get the path to the input file including the path of the running script.
  my $speciesPath = File::Spec->catfile(
                                        $FindBin::Bin,
                                        $self->{'config'}->get('localChecklistDir'),
                                        $self->{'config'}->get('localChecklistSubdirParsed'),
                                        $speciesFilename
                                       );

  # Open the species input file so we can do our processing.
  open(
       $self->{'fileHandle'},
       '< ' . $self->{'encoding'},
       $speciesPath
      )
    || die("$0: can't open $speciesPath for reading: $!");

  # Get ready to parse the CSV file.
  $self->{'csv'} = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module
