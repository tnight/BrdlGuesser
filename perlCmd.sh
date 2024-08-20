#!/bin/sh

export speciesFilename='ABA_Checklist-8.15.csv';  # The full data file.
# export speciesFilename='short.csv';  # A small data file for testing.

perl -ne 'if (m#,\w+,\d+$#) { print; }' $speciesFilename

# End of script
