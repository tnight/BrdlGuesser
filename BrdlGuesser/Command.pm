# I tried using the "new" (as of 2025) Corinna framework for this class,
# but the App::Cmd framework complained that the class hierarchy was not
# as it expects. Maybe someday the different frameworks will work
# together? Until then, we have to use the old-school Perl OO syntax.
#
# More information about Corinna can be found here:
# https://dev.to/ovid/bringing-modern-oo-to-perl-51ak

package BrdlGuesser::Command;

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Gain access to all the other modules we'll need.
use App::Cmd::Setup -command;
use File::Basename;
use FindBin;
use Log::Any qw($log);
use My::Config;
use Text::CSV;

#
# Constructor
#

sub new($$) {
  my ($class, $arg) = @_;

  # First, call the constructor of our superclass.
  my $self = $class->SUPER::new($arg);

  # Then, initialize the additional items we need for this subclass.
  $self->{'config'} = undef;
  $self->{'csv'} = undef;
  $self->{'encoding'} = ":encoding(UTF-8)";
  $self->{'exclusionRegex'} = undef;
  $self->{'fileHandle'} = undef;
  $self->{'inclusionRegexen'} = [];
  $self->{'searchPattern'} = '[A-Z]{4}'; # a generic search pattern that can be overridden by subclasses
  $self->{'speciesPath'} = undef;

  # Finally, re-bless the reference to be of this subclass.
  return bless($self, $class);
}

#
# Public instance methods
#

sub execute($$$) {
  my ($self, $opt, $args) = @_;

  # Get ready to do the work.
  $self->_initialize($opt, $args);

  # Do the work.
  my $matchCount = $self->_searchFile();

  # Now that the work is done, clean up after ourselves.
  $self->_cleanUp();

  # Return the result code for our search.
  return $matchCount > 0 ? 0 : 1;
}

sub validate_args($$$) {
  my ($self, $opt, $args) = @_;

  $self->usage_error("No args allowed") if @$args;
}

#
# Private instance methods
#

sub _cleanUp($) {
  my $self = shift();

  if (defined($self->{'fileHandle'})) {
    close($self->{'fileHandle'}) or die($log->fatal("$0: failed to close " . $self->{'speciesPath'} . ": $!"));
  }
}

sub _initialize($$$) {
  my ($self, $opt, $args) = @_;

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
    || die($log->fatal("$0: can't open " . $self->{'speciesPath'} . " for reading: $!\n\n" .
           "Did you run the ABA Checklist Fetcher script?\n\n"));

  # Get ready to parse the CSV file.
  $self->{'csv'} = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
}

sub _searchFile($) {
  my $self = shift();

  # Declare some local variables for convenience.
  my $matchCount = 0;
  my $searchPattern = $self->{'searchPattern'};

  # Make sure we have a search pattern, without which we cannot search.
  if (! defined($searchPattern)) {
    die($log->fatal("$0: no search pattern defined so we cannot search"));
  }

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

    # Search for a match with our search pattern. If not found, skip this species.
    if ($speciesCode !~ m/^$searchPattern$/) {
      next SPECIES;
    }

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

  if ($!) {
    die($log->fatal("$0: unexpected error while reading from " . $self->{'speciesPath'} . ": $!"));
  }

  return $matchCount;
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module
