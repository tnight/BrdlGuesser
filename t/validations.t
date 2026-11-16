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
use Test::More tests => 153;  # The number of tests we will run in this file.

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
my ($command, $extraArgument, @optionNames, @optionValues, $result, $searchTarget);

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
@optionNames = ('x');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]"]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
isnt($result->stderr, '', 'something sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message printed to stderr.
like($result->stderr, qr/Unknown\s+option/i, 'printed the error message that we expected');
like($result->stderr, qr/$optionNames[0]/i, 'printed the name of the unknown option');

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
@optionNames = ('p');
@optionValues = ('at___');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
@optionNames = ('x');
@optionValues = ('zbcdza');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
@optionNames = ('x');
@optionValues = ('abcd0');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
@optionNames = ('x');
@optionValues = ('abcd%');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
@optionNames = ('i');
@optionValues = ('z:1,z:2');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
@optionNames = ('i');
@optionValues = ('z:1,:4');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
like($result->error, qr/$optionValues[0]/i);

#
# Specify a value in the inclusion list that is longer than one character.
#
$command = 'search';
@optionNames = ('i');
@optionValues = ('z:1,qq:4');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
like($result->error, qr/$optionValues[0]/i);

#
# Include a number in the inclusion list.
#
$command = 'search';
@optionNames = ('i');
@optionValues = ('z:1,9:4');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
like($result->error, qr/$optionValues[0]/i);

#
# Include a punctuation character in the inclusion list.
#
$command = 'search';
@optionNames[0] = 'i';
@optionValues[0] = 'z:1,@:4';
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

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
like($result->error, qr/$optionValues[0]/i);

#
# Include a number in the search pattern.
#
$command = 'search';
@optionNames[0] = 'p';
@optionValues[0] = '__0_';
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Search\s+pattern.+\s+contains.+\s+invalid\s+characters/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/$optionValues[0]/i);

#
# Include a punctuation character in the search pattern.
#
$command = 'search';
@optionNames = ('p');
@optionValues = ('_B@_');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Search\s+pattern.+\s+contains.+\s+invalid\s+characters/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
like($result->error, qr/$optionValues[0]/i);

#
# Include the same letter twice in the exclusion list.
#
$command = 'search';
@optionNames = ('x');
@optionValues = ('abcdefb');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+appears\s+more\s+than\s+once/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc(substr($optionValues[0],-1,1));
like($result->error, qr/$searchTarget/);

#
# Specify two inclusion list entries for the same letter.
#
$command = 'search';
@optionNames = ('i', 'x');
@optionValues = ('b:2,c:1,b:4', 'RHT');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0], -$optionNames[1], $optionValues[1]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Found\s+too\s+many\s+instances.+\s+inclusion\s+list/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc(substr($optionValues[0],0,1));
like($result->error, qr/$searchTarget/);

#
# Include the same letter in the exclusion list and the inclusion list.
#
$command = 'search';
@optionNames = ('i', 'x');
@optionValues = ('b:2', 'BACD');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0], -$optionNames[1], $optionValues[1]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+appears.+\s+exclusion\s+list\s+and\s+inclusion\s+list/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc(substr($optionValues[0],0,1));
like($result->error, qr/$searchTarget/);

#
# Include the same letter in the exclusion list and the search pattern.
#
$command = 'search';
@optionNames = ('x', 'p');
@optionValues = ('b', '_BA_');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0], -$optionNames[1], $optionValues[1]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Letter\s+appears.+\s+exclusion\s+list\s+and\s+search\s+pattern/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc($optionValues[0]);
like($result->error, qr/$searchTarget/);

#
# Specify more than two slots for an inclusion list entry.
#
$command = 'search';
@optionNames = ('i', 'x');
@optionValues = ('b:234', 'ACD');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0], -$optionNames[1], $optionValues[1]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Too\s+many\s+slots\s+found\s+for\s+letter/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc($optionValues[0]);
like($result->error, qr/$searchTarget/);

#
# Give a minimum occurrence count that is less than one for an inclusion list entry.
#
$command = 'search';
@optionNames = ('i', 'x');
@optionValues = ('b:234', 'ACD');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0], -$optionNames[1], $optionValues[1]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Too\s+many\s+slots\s+found\s+for\s+letter/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc($optionValues[0]);
like($result->error, qr/$searchTarget/);

#
# Give a minimum occurrence count that is greater than two for an inclusion list entry.
#
$command = 'search';
@optionNames = ('i', 'x');
@optionValues = ('b:14:3', 'ACD');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0], -$optionNames[1], $optionValues[1]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Invalid\s+minimum\s+count\s+found\s+for\s+letter/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc($optionValues[0]);
like($result->error, qr/$searchTarget/);

#
# Give a minimum occurrence count that is greater than the maximum occurrence count for an inclusion list entry.
#
$command = 'search';
@optionNames = ('i', 'x');
@optionValues = ('b:14:2:1', 'ACD');
$result = test_app($brdlGuesser => [$command, "-$optionNames[0]", $optionValues[0], -$optionNames[1], $optionValues[1]]);

# Verify that we have created an error condition.
isnt($result->error, undef, 'threw an exception');
isnt($result->exit_code, 0, 'numeric exit code is not zero');
is($result->stderr, '', 'nothing sent to stderr');
is($result->stdout, '', 'nothing sent to stdout');

# We find the expected usage details within the error output.
like($result->error, qr/$command/, 'printed the usage details for the command that we expected');

# We find the expected error message within the error output.
like($result->error, qr/Minimum\s+count\s+for\s+letter\s+must\s+be\s+less/i, 'printed the error message that we expected');

# We find the expected invalid character within the error output.
$searchTarget = uc($optionValues[0]);
like($result->error, qr/$searchTarget/);

# End of test script.
