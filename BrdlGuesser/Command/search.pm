package BrdlGuesser::Command::search;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;

# Define our usage message as a constant.
use constant USAGE_DESCRIPTION => <<END;
%c search %o

This command will search for a four-letter Alpha code using a search
pattern. The pattern is case-insensitive. That is, both uppercase and
lowercase letters will successfully match the four-letter Alpha code.
To represent an unknown letter, use the underscore ('_').

NOTE: At least one of the -i, -p, or -x options is required.

EXAMPLES
shell> %c search -p R_BU
shell> %c search -p _ar_
shell> %c search -p G_A_ -x bmos
shell> %c search -p G_A_ -i tw
END

#
# Public instance methods
#

sub abstract() {
  return "search for the four-letter Alpha code of a bird species using a search pattern";
}

sub opt_spec() {
  return(
         [ "pattern|p=s", "Search for the given pattern" ],
         [ "include|i=s", "Only include guesses that contain all of the given letters" ],
         [ "exclude|x=s", "Exclude guesses that contain any of the given letters" ]
        );
}

sub validate_args($$$) {
  my ($self, $opt, $args) = @_;

  # Call our superclass method so it can do the necessary validation.
  $self->SUPER::validate_args($opt, $args);

  #
  # Do the further validation that our subclass needs.
  #

  # The reason we look for the mandatory parameters here, rather than
  # using GetOpts::Long::Descriptive (GLD) to do the validation, is
  # because I was not able to find a feature of GLD that can enforce
  # the rule that at least one of the parameters must appear, but that
  # it is also valid for any and all of them to appear. GLD has a
  # feature called "one of" but that enforces that only one of the
  # required parameters may appear, which is not how we want it to work
  # in this case.
  $self->usage_error("Must include at least one of the 'exclude', 'include', or 'pattern' parameters")
    if (
        ! defined($opt->exclude) &&
        ! defined($opt->include) &&
        ! defined($opt->pattern)
       );

  # Declare a local variable for convenience.
  my $pattern = $opt->pattern;

  # Validate that the search pattern has exactly four characters.
  $self->usage_error("Search pattern [$pattern] does not have exactly four characters")
    if (
        defined($opt->pattern) &&
        length($opt->pattern) != 4
       );

  # Validate that the search pattern contains no invalid characters.
  $self->usage_error("Search pattern [$pattern] contains one or more invalid characters, but only letters and underscores are allowed")
    if (
        defined($opt->pattern) &&
        $opt->pattern =~ m/[^_[:alpha:]]/
       );

  # Validate that no letter appears in both the exclusion and inclusion
  # lists.
  if (
      defined($opt->exclude) &&
      defined($opt->include)
     )
  {
    $self->_validateListsAsMutuallyExclusive(
                                     $opt->exclude,
                                     $opt->include,
                                     'inclusion list'
                                    );
  }

  # Validate that no letter appears in both the exclusion list and the
  # search pattern.
  if (
      defined($opt->exclude) &&
      defined($opt->pattern)
     )
  {
    $self->_validateListsAsMutuallyExclusive(
                                     $opt->exclude,
                                     $opt->pattern,
                                     'search pattern'
                                    );
  }
}

sub usage_desc() {
  return USAGE_DESCRIPTION;
}

#
# Private instance methods
#

sub _getStringAsArray($$) {
  my $self = shift();
  my $inclusionString = shift();

  return split(
               //,
               uc($inclusionString)
              );
}

sub _initialize($$$) {
  my ($self, $opt, $args) = @_;

  # Call our superclass method so it can do the necessary initialization.
  $self->SUPER::_initialize($opt, $args);

  #
  # Do the further initialization that our subclass needs.
  #

  # Configure the search pattern based on our command-line options.
  if (defined($opt->pattern)) {
    $self->{'searchPattern'} = uc($opt->pattern);
    $self->{'searchPattern'} =~ s#_#[A-Z]#g;
  }

  # Configure the exclusion pattern based on our command-line options.
  if (defined($opt->exclude)) {
    my $exclusionPattern = '[' . uc($opt->{'exclude'}) . ']';
    $self->{'exclusionRegex'} = qr/$exclusionPattern/;
  }

  # Configure the inclusion patterns based on our command-line options.
  if (defined($opt->include)) {
    my @inclusionRegexen = ();
    foreach my $inclusionLetter ($self->_getStringAsArray($opt->include)) {
      push(@inclusionRegexen, qr/$inclusionLetter/);
    }
    $self->{'inclusionRegexen'} = \@inclusionRegexen;
  }
}

sub _validateListsAsMutuallyExclusive($$$$) {
  my $self = shift();
  my $exclusionString = shift();
  my $inclusionString = shift();
  my $inclusionFieldDisplayName = shift();

  my $exclusionStringUppercase = uc($exclusionString);
  my $inclusionStringNoUnderscores = uc($inclusionString);
  $inclusionStringNoUnderscores =~ s/\Q_\E//g;

  foreach my $inclusionLetter ($self->_getStringAsArray($inclusionStringNoUnderscores)) {
    if ($exclusionStringUppercase =~ m/$inclusionLetter/) {
      $self->usage_error(
          "Letter appears both in exclusion list and " .
          "$inclusionFieldDisplayName: " .
          $inclusionLetter
         );
    }
  }
}

1;

# end of module
