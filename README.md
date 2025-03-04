# BrdlGuesser
## Description
Guess the possible BRDL answers given an optional pattern as a starting point. Use one or more underscores (`_`) as single-letter wildcards. Some letters can be excluded from the matching species Alpha codes using the -x|--exclude option. Conversely, some letters can be included in all the matching species Alpha codes using the -i|--include option. Use the -d|--dump option to display all of the possible BRDL answers.

One of the -d|--dump, -i|--include, -p|--pattern, or -x|--exclude options is required. If -p is given, it overrides any -d option.

**NOTES:**
* Both the search pattern and the letters to be included and excluded can be given as uppercase or lowercase, and will still match.
* The same letter cannot appear in both the exclusion and inclusion lists.

## Examples
### Display a single, matching BRDL solution
```
shell> brdlGuesser.pl -p BBMA
   1. BBMA: Black-billed Magpie
```

### Display BRDL solutions that match a pattern
```
shell> brdlGuesser.pl -p R__L
   1. RFBL: Red-flanked Bluetail
   2. RWBL: Red-winged Blackbird
   3. RUBL: Rusty Blackbird
```

### Display BRDL solutions that match a pattern but do not contain some letters
```
shell> brdlGuesser.pl -p G_A_ -x MOS
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

### Display BRDL solutions that match a pattern and contain certain letters
```
shell> brdlGuesser.pl -p G_A_ -i TW
   1. GBAT: Gray-backed Tern
   2. GRAW: Gray Wagtail
```

### Display all possible BRDL solutions
```
shell> brdlGuesser.pl -d
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
