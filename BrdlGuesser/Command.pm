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
  $self->{'exclusionRegex'} = undef;
  $self->{'fileHandle'} = undef;
  $self->{'inclusionRegexen'} = [];
  $self->{'searchPattern'} = undef;
  $self->{'speciesPath'} = undef;

  # Finally, re-bless to our subclass.
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
  $self->{'speciesPath'} = File::Spec->catfile(
                                               $FindBin::Bin,
                                               $self->{'config'}->get('localChecklistDir'),
                                               $self->{'config'}->get('localChecklistSubdirParsed'),
                                               $speciesFilename
                                              );

  # Open the species input file so we can do our processing.
  open(
       $self->{'fileHandle'},
       '< ' . $self->{'encoding'},
       $self->{'speciesPath'}
      )
    || die("$0: can't open " . $self->{'speciesPath'} . " for reading: $!");

  # Get ready to parse the CSV file.
  $self->{'csv'} = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
}

sub _searchFile() {
  my $self = shift();

  # Declare some local variables for convenience.
  my $matchCount = 0;
  my $searchPattern = $self->{'searchPattern'};

SPECIES:
  while (my $row = $self->{'csv'}->getline($self->{'fileHandle'})) {
    my (
        $group,
        $speciesNameEnglish,
        $speciesNameFrench,
        $speciesLatinName,
        $speciesCode,
        $speciesAbundance
       ) = @$row;

    # Search for a match with our search pattern.
    if ($speciesCode =~ m/^$searchPattern$/) {
      # Exclude species codes containing the letters we were told to exclude.
      if (
          defined($self->{'exclusionRegex'}) &&
          $speciesCode =~ $self->{'exclusionRegex'}
         ) {

        next SPECIES;
      }

      # Only include species codes containing all the letters we were
      # told to include.
      if (scalar(@{$self->{'inclusionRegexen'}})) {
        foreach my $inclusionRegex (@{$self->{'inclusionRegexen'}}) {
          if ($speciesCode !~ $inclusionRegex) {
            next SPECIES;
          }
        }
      }

      # Our pattern matched, so output the result.
      printf(
             "%4d. %s: %s\n",
             ++$matchCount,
             $speciesCode,
             $speciesNameEnglish
            );
    }
  }
  if ($!) {
    die("$0: unexpected error while reading from " . $self->{'speciesPath'} . ": $!");
  }

  return $matchCount;
}

# TODOTODO: Figure out how we can clean things up once the work is done.
# In the case of the brdlGuesser.pl stand-alone script, the clean-up is
# done at the end of the main() method.
#
# Maybe I just have to roll it myself with a custom _cleanup() method
# like I did with the _initialize() method?

# Return a true value so Perl will know that everything is OK.
1;

# End of module
