# BrdlGuesser
## Description
These two modes of operation can be selected based on the command given:
* **dump:** display every possible BRDL answer, which is a long list of over a thousand species.
* **search:** Guess the possible BRDL answers given an optional pattern as a starting point. Use one or more underscores (`_`) as single-letter wildcards. Some letters can be excluded from the matching species Alpha codes using the `-x|--exclude` option. Conversely, some letters can be included in all the matching species Alpha codes using the `-i|--include` option.

## Notes
* When searching, one of the `-i|--include`, `-p|--pattern`, or `-x|--exclude` options is required.
* Both the search pattern and the letters to be included and excluded can be given as uppercase or lowercase, and will still match.
* The same letter cannot appear in both the exclusion and inclusion lists.
* The same letter cannot appear more than once in the exclusion list.
* The same letter cannot appear more than once in the inclusion list.

## Command line options
* `-p|--pattern <pattern>` Search for solutions using the specified pattern. Use an underscore (`_`) as a single-letter wildcard to denote an unknown letter.
* `-x|--exclude <letter-list>` When searching, exclude solutions that contain any of the listed letters. The format of the list is a simple string of letters.
* `-i|--include <inclusion-field-list>` When searching, only include solutions that match the inclusion criteria specified in the inclusion field list. The list is comma-separated. The fields within each entry in the list are separated by colons. The fields in each entry of the list are as follows:
  * A letter (required)
  * A list of slots where we know the letter is not present (required)
  * The minimum count of matches required for the letter (optional)
    * If a minimum count is specified, it must be either 1 or 2
    * If no minimum count is specified, the default minimum count of 1 will be used

## Examples
### Display a single, matching BRDL solution
```
shell> brdlGuesser.pl search -p BBMA
   1. BBMA: Black-billed Magpie
```

### Display BRDL solutions that match a pattern
```
shell> brdlGuesser.pl search -p R__L
   1. RFBL: Red-flanked Bluetail
   2. RWBL: Red-winged Blackbird
   3. RUBL: Rusty Blackbird
```

### Display BRDL solutions that match a pattern but do not contain some letters
```
shell> brdlGuesser.pl search -p G_A_ -x MOS
   1. GRAP: Gray Partridge
   2. GRAF: Gray Francolin
   3. GBAN: Groove-billed Ani
   4. GRAU: Great Auk (extinct, 1844)
   5. GBAT: Gray-backed Tern
   6. GRAH: Gray Heron
   7. GRAK: Gray Kingbird
   8. GRAW: Gray Wagtail
   9. GRAM: Greater Amakihi
```

### Display BRDL solutions that match a pattern and contain a certain letter but not in slot 1
```
shell> brdlGuesser.pl search -p _E_A -i H:1
   2. FEHA: Ferruginous Hawk
```

### Display BRDL solutions that match a pattern and contain certain letters but not in certain slots
```
shell> brdlGuesser.pl search -p L___ -i e:3,o:2
   1. LEOW: Long-eared Owl
   2. LEWO: Lewis's Woodpecker
   3. LEGO: Lesser Goldfinch
```

### Display BRDL solutions that contain at least a certain number of a certain letter but not in certain slots
```
shell> brdlGuesser.pl search -i e:14:2
   1. REEG: Reddish Egret
   2. MEEG: Medium Egret
   3. VEER: Veery
```

### Display all possible BRDL solutions
```
shell> brdlGuesser.pl dump
   1. BBWD: Black-bellied Whistling-Duck
   2. FUWD: Fulvous Whistling-Duck
   3. EMGO: Emperor Goose
   4. SNGO: Snow Goose
   5. ROGO: Ross's Goose
   6. GRGO: Graylag Goose
   7. GWFG: Greater White-fronted Goose
   8. LWFG: Lesser White-fronted Goose
   9. TABG: Taiga Bean-Goose
  10. TUBG: Tundra Bean-Goose

[...]

1134. RCCA: Red-crested Cardinal
1135. YBCA: Yellow-billed Cardinal
1136. BGTA: Blue-gray Tanager (1969-1982)
1137. SAFI: Saffron Finch
1138. BGRA: Blue-black Grassquit
1139. RLHO: Red-legged Honeycreeper
1140. BANA: Bananaquit
1141. YFGR: Yellow-faced Grassquit
1142. BFGR: Black-faced Grassquit
1143. MOSE: Morelet's Seedeater
```

## Installation
Before running the BrdlGuesser script for the first time, you will need to fetch the bird checklist from the American Birding Association (ABA) website. To do this, you can run the [ABA Checklist Fetcher](#abaChecklistFetcherHeading) script included in this software package. It is also a good idea to run the ABA Checklist Fetcher script periodically to retrieve the updated checklist file. Typically, the ABA updates the checklist once or twice per year.

# <a name="abaChecklistFetcherHeading"></a> ABA Checklist Fetcher
## Description
Fetch the latest version of the American Birding Association (ABA) bird checklist. This checklist contains the four-letter alphabetic codes that can be possible solutions to the BRDL puzzle.

## Running on Windows
If you are running the ABA Checklist Fetcher script on Windows, you will need to run it on Windows 10 or greater. You will also need to run your command window or Git Bash window as Administrator. This is needed so that symbolic links will work correctly.
