#!/usr/bin/env sh

checklistFile1=$1
checklistFile2=$2

### for birdCode in AMCR AMCZ
for birdCode in $(cat autobird.txt)
do
    grep -i $birdCode $checklistFile1 $checklistFile2 > /dev/null
    if [ $? != 0 ]
    then
        echo "Bird code $birdCode not found."
    fi
done

# End of script
