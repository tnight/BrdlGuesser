#!/usr/bin/env perl

# Do our best to find errors as early as possible.
use strict;
use warnings;

# Make sure we can find our local module(s).
use File::Basename;
use File::Spec;
my $runningScriptDirName;
BEGIN {
  $runningScriptDirName = File::Spec->catfile(
    dirname(__FILE__),
    '..'
  );
}

use lib $runningScriptDirName;
chdir $runningScriptDirName or die "Cannot chdir to project root [$runningScriptDirName]: $!";

# Get ready for testing in general.
use Test::More tests => 83;  # The number of tests we will run in this file.

# Get ready for App::Cmd testing in particular.
use App::Cmd::Tester;

# Gain access to our application module.
use BrdlGuesser;

# Instantiate our application instance.
my $brdlGuesser = BrdlGuesser->new(
                                   {
                                    'runningScriptDirName' => $runningScriptDirName,
                                    'show_version_cmd' => 1
                                   }
                                  );

# Declare some local variables that we will reuse.
my ($command, $extraArgument, $option, $optionValue, $result);

#
# Use an invalid command name.
#
$command = 'badCommand';
$result = test_app($brdlGuesser => [qw($command)]);

# Verify that we have created an error condition.
is($result->error, undef, 'threw no exceptions');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
isnt($result->stderr, '', 'something sent to stderr');
isnt($result->stdout, '', 'something sent to stdout');

# We find the expected error message printed to stdout.
like($result->stdout, qr/Unrecognized\s+command/i, 'printed the error message that we expected');
like($result->stdout, qr/\$command/i, 'printed a placeholder for the name of the unrecognized command');
like($result->stdout, qr/Usage/, 'printed the header of the usage message that we expected');

# We find the expected usage details message printed to stderr.
like($result->stderr, qr/commands/, 'printed the details of the usage message that we expected');

#
# Use an invalid option.
#
$command = 'dump';
$option = 'x';
$result = test_app($brdlGuesser => [$command, "-$option"]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
isnt($result->stderr, '', 'something sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message printed to stderr.
like($result->stderr, qr/Unknown\s+option/i, 'printed the error message that we expected');
like($result->stderr, qr/$option/i, 'printed the name of the unknown option');

#
# Add an extra, erroneous argument.
#
$command = 'dump';
$extraArgument = 'blah';
$result = test_app($brdlGuesser => [$command, $extraArgument]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected message within the error output.
like($result->error, qr/No\s+args\s+allowed/i, 'printed the error message that we expected');

#
# Use a search pattern that is not the correct length.
#
$command = 'search';
$option = 'p';
$optionValue = 'at___';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Search\s+pattern.+\s+does\s+not\s+have\s+exactly\s+four\s+characters/i, 'printed the error message that we expected');

#
# Include the same letter twice in the exclusion list.
#
$command = 'search';
$option = 'x';
$optionValue = 'zbcdza';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+appears\s+more\s+than\s+once/i, 'printed the error message that we expected');

# We find the expected duplicate letter within the error output.
like($result->error, qr/Z/);

#
# Include a number in the exclusion list.
#
$command = 'search';
$option = 'x';
$optionValue = 'abcd0';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Found\s+non-alphabetic\s+character/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/0/);

#
# Include a punctuation character in the exclusion list.
#
$command = 'search';
$option = 'x';
$optionValue = 'abcd%';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Found\s+non-alphabetic\s+character/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/%/);

#
# Include the same letter twice in the inclusion list.
#
$command = 'search';
$option = 'i';
$optionValue = 'z:1,z:2';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Found\s+too\s+many\s+instances/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/Z/);

#
# Specify a value in the inclusion list that is shorter than one character.
#
$command = 'search';
$option = 'i';
$optionValue = 'z:1,:4';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+is\s+shorter\s+or\s+longer\s+than\s+one\s+character/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/$optionValue/i);

#
# Specify a value in the inclusion list that is longer than one character.
#
$command = 'search';
$option = 'i';
$optionValue = 'z:1,qq:4';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+is\s+shorter\s+or\s+longer\s+than\s+one\s+character/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/$optionValue/i);

#
# Include a number in the inclusion list.
#
$command = 'search';
$option = 'i';
$optionValue = 'z:1,9:4';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+contains\s+invalid\s+character/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/$optionValue/i);

#
# Include a punctuation character in the inclusion list.
#
$command = 'search';
$option = 'i';
$optionValue = 'z:1,@:4';
$result = test_app($brdlGuesser => [$command, "-$option", $optionValue]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+contains\s+invalid\s+character/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/$optionValue/i);

#
# Include a number in the search pattern.
#

#
# Include a punctuation character in the search pattern.
#

#
# Include the same letter in the exclusion list and the inclusion list.
#

#
# Include the same letter in the exclusion list and the search pattern.
#

#
# Specify more than two slots for an inclusion list entry.
#

#
# Give a minimum occurrence count that is less than one for an inclusion list entry.
#

#
# Give a minimum occurrence count that is greater than four for an inclusion list entry.
#

#
# Give a minimum occurrence count that is greater than the maximum occurrence count for an inclusion list entry.
#

# TODOTODO: Add more tests.

# End of test script.
