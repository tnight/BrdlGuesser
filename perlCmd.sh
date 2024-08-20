#!/bin/sh

perl -ne 'if (m#,\w+,\d+$#) { print; }' short.csv
