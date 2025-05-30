package BrdlGuesser::Command::search;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;

# Define our usage message as a constant.
use constant USAGE_DESCRIPTION => <<END;
%c search %o

This command will search for a four-letter Alpha code using a search
pattern. To represent an unknown letter, use the underscore ('_').
One of the -d, -p, or -x options is required. If -p is given, it
overrides any -d option.

EXAMPLES
shell> %c search -p R_BU
shell> %c search -p _ar_
shell> %c search -p G_A_ -x bmos
shell> %c search -p G_A_ -i tw
END

#
# Public instance methods
#

sub abstract {
  return "search for the four-letter Alpha code of a bird species using a search pattern";
}

sub opt_spec {
  return(
         [ "pattern|p=s", "Search for the given pattern (REQUIRED)" ],
         [ "include|i=s", "Only include guesses that contain all of the given letters" ],
         [ "exclude|x=s", "Exclude guesses that contain any of the given letters" ]
        );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  # Call our superclass method so it can do the necessary validation.
  $self->SUPER::validate_args($opt, $args);

  #
  # Do the further validation that our subclass needs.
  #

  # TODOTODO: Update the code below, because it contains a bug. The
  # pattern parameter is actually *NOT* mandatory. In some cases, we
  # might know that one or more letters need to be included, and that
  # other letters need to be excluded, but we might not know the exact
  # positions yet.

  # The reason we look for the mandatory parameter here rather than
  # using the "required" feature of GetOpts::Long::Descriptive is
  # because doing it that way throws a strange error that will
  # confuse our users. This way, we can control the message that is
  # displayed when the paramewter is missing.
  $self->usage_error("Mandatory parameter 'pattern' missing")
    if (! defined($opt->pattern));

  # Declare a local variable for convenience.
  my $pattern = $opt->pattern;

  # Validate that the search pattern has exactly four characters.
  $self->usage_error("Search pattern [$pattern] does not have exactly four characters")
    if (length($opt->pattern) != 4);

  # Validate that the search pattern contains no invalid characters.
  $self->usage_error("Search pattern [$pattern] contains one or more invalid characters, but only letters and underscores are allowed")
    if ($opt->pattern =~ m/[^_[:alpha:]]/);

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

sub usage_desc {
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

sub _initialize() {
  my ($self, $opt, $args) = @_;

  # Call our superclass method so it can do the necessary initialization.
  $self->SUPER::_initialize($opt, $args);

  #
  # Do the further initialization that our subclass needs.
  #

  # Configure the search pattern based on our command-line options.
  $self->{'searchPattern'} = uc($opt->pattern);
  $self->{'searchPattern'} =~ s#_#[A-Z]#g;

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
