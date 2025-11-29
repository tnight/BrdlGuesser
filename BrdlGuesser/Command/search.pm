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
shell> %c search -p _E_A -i h:^s1
shell> %c search -p L___ -i e:^s3:2

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
         [ "include|i=s", "Only include guesses that contain all of the given letters in the correct slots and with the correct count" ],
         [ "exclude|x=s", "Exclude guesses that contain any of the given letters" ]
        );
}

sub validate_args($$$) {
  my ($self, $opt, $args) = @_;

  # Call our superclass method so it can do the necessary validation.
  $self->SUPER::validate_args($opt, $args);

  # TODOTODO: Remove after testing.
  use Data::Dumper;
  print Data::Dumper->Dump([$opt], [qw(opt)]);

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

  # Validate that no letter appears more than once in the exclusion list.
  if (defined($opt->exclude)) {
    $self->_validateExclusionList(
                                  $opt->exclude,
                                  'exclusion list'
                                 );
  }

  # Validate that no letter appears more than four times in the
  # inclusion list.
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

  # Configure the inclusion patterns based on our command-line options.
  if (defined($opt->include)) {
    foreach my $inclusionLetter ($self->_getStringAsArray($opt->include)) {
      $self->{'inclusionLetterHash'}{$inclusionLetter}{'regex'} = qr/$inclusionLetter/;
    }
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

sub _validateExclusionList($$$) {
  my $self = shift();
  my $exclusionString = shift();
  my $exclusionFieldDisplayName = shift();

  my $exclusionStringUppercase = uc($exclusionString);

  try {
    $self->_getStringAsHash($exclusionStringUppercase);
  }
  catch {
    $self->usage_error(
                       "Letter appears more than once in " .
                       "$exclusionFieldDisplayName: " .
                       $_->{'errorContext'}->{'letter'}
                      );
  };
}

sub _validateInclusionList($$$) {
  my $self = shift();
  my $inclusionString = shift();
  my $inclusionFieldDisplayName = shift();

  my $inclusionStringUppercase = uc($inclusionString);
  my %inclusionLetterHash = ();

  try {
    # Ensure that no letter appears more than four times in the
    # inclusion list because the puzzle only has four letters.
    %inclusionLetterHash = $self->_getStringAsHash(
                                                   $inclusionStringUppercase,
                                                   4
                                                  );
  }
  catch {
    $self->usage_error(
                       "Letter appears more than four times in " .
                       "$inclusionFieldDisplayName: " .
                       $_->{'errorContext'}->{'letter'}
                      );
  };

  return %inclusionLetterHash;
}

sub _getStringAsHash($$$) {
  my $self = shift();
  my $string = shift();
  my $maxInstancesAllowed = shift() || 1;

  my %letterHash = ();
  my @letterArray = $self->_getStringAsArray($string);

  foreach my $letter (@letterArray) {
    if (! exists($letterHash{$letter})) {
      $letterHash{$letter} =
        {
         count => 1,
         regex => undef
        };
    }
    else {
      $letterHash{$letter}{'count'}++;
    }

    if ($letterHash{$letter}{'count'} > $maxInstancesAllowed) {
      die(
          {
           errorCode    => 'MAX001',
           errorContext => { letter => $letter },
           errorMessage => 'Found too many instances of a letter'
          }
         );
    }
  }

  %letterHash;
}

1;

# end of module
