package TestHelper;

use strict;
use warnings;

my $runningScriptDirName;

BEGIN {
  use File::Basename;
  use File::Spec;
  $runningScriptDirName = File::Spec->catfile(
    dirname(__FILE__),
    '..',
    '..'
  );
}

sub setup() {
  # Make sure we can find our local module(s).
  use lib $runningScriptDirName;
  chdir $runningScriptDirName or die "Cannot chdir to project root [$runningScriptDirName]: $!";

  # Gain access to our application module.
  use BrdlGuesser;

  # Instantiate our application instance.
  my $brdlGuesser = BrdlGuesser->new(
    {
      'runningScriptDirName' => $runningScriptDirName,
      'show_version_cmd' => 1
    }
  );

  # Return the object under test.
  return $brdlGuesser;
}

# Return a true value so Perl will know that everything is OK.
1;

# End of module
