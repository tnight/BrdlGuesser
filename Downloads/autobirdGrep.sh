#!/usr/bin/env sh

### for birdCode in AMCR AMCZ
for birdCode in $(cat autobird.txt)
do
    grep -i $birdCode "$@" > /dev/null
    if [ $? != 0 ]
    then
        echo "Bird code $birdCode not found."
    fi
done

# End of script
