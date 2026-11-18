package TestHelper;

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use FindBin;
use lib "$FindBin::Bin/../lib";

# Gain access to our application module.
use BrdlGuesser;

sub setup() {
  # Instantiate our application instance.
  my $brdlGuesser = BrdlGuesser->new({'show_version_cmd' => 1});

  # Return the object under test.
  return $brdlGuesser;
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module
