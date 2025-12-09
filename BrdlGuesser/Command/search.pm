package BrdlGuesser::Command::search;

# Gain access to all the pragmas and modules we'll need.
use strict;
use warnings;
use BrdlGuesser -command;
use Try::Tiny;

# Define our usage message as a constant.
use constant USAGE_DESCRIPTION => <<END;
%c search %o

This command will search for a four-letter Alpha code using a search
pattern. The pattern is case-insensitive. That is, both uppercase and
lowercase letters will successfully match the four-letter Alpha code.
To represent an unknown letter, use the underscore ('_').

NOTE: Both the search pattern and the letters to be included and
      excluded can be given as uppercase or lowercase, and will still match.
NOTE: At least one of the -i, -p, or -x options is required.
NOTE: The same letter cannot appear in both the exclusion and inclusion lists.
NOTE: The same letter cannot appear more than once in the exclusion list.
NOTE: The same letter cannot appear more than once in the inclusion list.

EXAMPLES
shell> %c search -p R_BU
shell> %c search -p _ar_
shell> %c search -p G_A_ -x mos
shell> %c search -p _E_A -i h:1
shell> %c search -p L___ -i e:3
shell> %c search -i e:14:2

For more detailed usage information, see the README file.

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
         [ "include|i=s", "Only include guesses that contain all of the given letters in the correct slots" ],
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

  # Validate the exclusion list.
  if (defined($opt->exclude)) {
    $self->_validateExclusionList(
                                  $opt->exclude,
                                  'exclusion list'
                                 );
  }

  # Validate the inclusion list.
  if (defined($opt->include)) {
    my %inclusionLetterHash = $self->_validateInclusionList(
                                                            $opt->include,
                                                            'inclusion list'
                                                           );
    $self->{'inclusionLetterHash'} = \%inclusionLetterHash;
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
  my $string = shift();

  return split(
               //,
               uc($string)
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
    if ($exclusionStringUppercase =~ m/\Q$inclusionLetter\E/) {
      $self->usage_error(
          "Letter appears both in exclusion list and " .
          "$inclusionFieldDisplayName: " .
          $inclusionLetter
         );
    }
  }
}

sub _validateExclusionList($$$) {
  my $self = shift();
  my $exclusionString = shift();
  my $exclusionFieldDisplayName = shift();

  my $exclusionStringUppercase = uc($exclusionString);

  try {
    $self->_validateStringNoNonAlphaChars($exclusionStringUppercase);
  }
  catch {
    $self->usage_error(
                       "Found non-alphabetic character in " .
                       "$exclusionFieldDisplayName: " .
                       $_->{'errorContext'}->{'element'}
                      );
  };

  try {
    $self->_validateStringNoDuplicateChars($exclusionStringUppercase);
  }
  catch {
    $self->usage_error(
                       "Letter appears more than once in " .
                       "$exclusionFieldDisplayName: " .
                       $_->{'errorContext'}->{'element'}
                      );
  };
}

sub _validateListNoDuplicateElements($$) {
  my $self = shift();
  my $list = shift();

  my %elementHash = ();

  foreach my $element (@$list) {
    if (exists($elementHash{$element})) {
      die(
          {
           errorCode    => 'MAX001',
           errorContext => { element => $element },
           errorMessage => 'Found too many instances of an element'
          }
         );
    }

    $elementHash{$element} = 1;
  }
}

sub _validateStringNoDuplicateChars($$) {
  my $self = shift();
  my $string = shift();

  my @letterArray = $self->_getStringAsArray($string);
  $self->_validateListNoDuplicateElements(\@letterArray);
}

sub _validateStringNoNonAlphaChars($$) {
  my $self = shift();
  my $string = shift();

  # Use a POSIX character class to look for non-alphabetic characters.
  if ($string =~ m/([^[:alpha:]])/) {
    my $char = $1;
    die(
        {
         errorCode    => 'ALPHA001',
         errorContext => { element => $char },
         errorMessage => 'Found non-alpha element'
        }
       );
  }
}

sub _validateInclusionList($$$) {
  my $self = shift();
  my $inclusionString = shift();
  my $inclusionFieldDisplayName = shift();

  try {
    return $self->_convertInclusionListOptionToHash(uc($inclusionString));
  }
  catch {
    $self->usage_error(
                       $_->{'errorMessage'} .
                       "$inclusionFieldDisplayName: " .
                       $_->{'errorContext'}->{'element'}
                      );
  };
}

sub _convertInclusionListOptionToHash($$) {
  my $self = shift();
  my $string = shift();

  my %letterHash = ();
  my @slots = ();

  # At this point, we know that the string is not empty because our
  # prior argument validation logic has already run.
  my @fields = split(/,/, $string);

  foreach my $field (@fields) {
    my ($letter, $slots, $count) = split(/:/, $field);

    # Validate that the letter is alphabetic and has only one character.
    die(
        {
         errorCode    => 'InvalidLtr001',
         errorContext => { element => $string },
         errorMessage => 'Letter is shorter or longer than one character in '
        }
       )
      if (length($letter) != 1);

    # Validate that the letter is alphabetic.
    die(
        {
         errorCode    => 'InvalidLtr001',
         errorContext => { element => $string },
         errorMessage => 'Letter contains invalid character(s) in '
        }
       )
      if ($letter =~ m/[^[:alpha:]]/);

    # Validate that the slots for the letter are not missing.
    die(
        {
         errorCode    => 'MissingSlots001',
         errorContext => { element => $letter },
         errorMessage => 'Slots for letter are missing from '
        }
       )
      if (! $slots);

    # Validate that the slots are numeric and in the correct numeric range.
    die(
        {
         errorCode    => 'InvalidSlots001',
         errorContext => { element => $string },
         errorMessage => 'One or more invalid slots were found for letter. Only numbers from 1-4 are allowed in '
        }
       )
      if ($slots =~ m/[^1-4]/);

    @slots = $self->_getStringAsArray($slots);

    # Validate that we have either one or two slots, not more.
    die(
        {
         errorCode    => 'TooManySlots001',
         errorContext => { element => $string },
         errorMessage => 'Too many slots found for letter. Only one or two slots are allowed in '
        }
       )
      if (@slots != 1 && @slots != 2);

    if (! $count) {
      # No count was specified, so set the count to the default value.
      $count = 1;
    }

    # Validate that count is either 1 or 2. No other values are allowed.
    die(
        {
         errorCode    => 'InvalidCount001',
         errorContext => { element => $string },
         errorMessage => 'Invalid count found for letter. Only the values "1" and "2" are allowed in '
        }
       )
      if ($count != 1 && $count != 2);

    die(
        {
         errorCode    => 'MAX001',
         errorContext => { element => $letter },
         errorMessage => 'Found too many instances of a letter in '
        }
       )
      if (exists($letterHash{$letter}));

    $letterHash{$letter} =
      {
       count => $count,
       regex => qr/$letter/,
       slots => [ @slots ]
      };
  }

  %letterHash;
}

1;

# end of module
