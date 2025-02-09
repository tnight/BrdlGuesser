# BrdlGuesser
## Description
Guess the possible BRDL answers given an optional pattern as a starting point. Use one or more asterisks (`*`) as single-letter wildcards. Some letters can be excluded from the matching species Alpha codes using the -x|--exclude option. Conversely, some letters can be included in all the matching species Alpha codes using the -i|--include option. Use the -d|--dump option to display all of the possible BRDL answers.

One of the -d|--dump, -i|--include, -p|--pattern, or -x|--exclude options is required. If -p is given, it overrides any -d option.

**NOTES:**
* Both the search pattern and the letters to be included and excluded can be given as uppercase or lowercase, and will still match.
* The same letter cannot appear in both the exclusion and inclusion lists.
* To prevent the shell from interpreting any asterisks in your pattern, enclose the pattern with single quotes.

## Examples
### Display a single, matching BRDL solution
```
shell> brdlGuesser.pl -p BBMA
   1. BBMA: Black-billed Magpie
```

### Display BRDL solutions that match a pattern
```
shell> brdlGuesser.pl -p 'R**L'
   1. RFBL: Red-flanked Bluetail
   2. RWBL: Red-winged Blackbird
   3. RUBL: Rusty Blackbird
```

### Display BRDL solutions that match a pattern but do not contain some letters
```
shell> brdlGuesser.pl -p 'G*A*' -x MOS
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
shell> brdlGuesser.pl -p 'G*A*' -i TW
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
