# BrdlGuesser
## Description
Guess the possible BRDL answers given an optional pattern as a starting point. Use one or more asterisks (`*`) as single-letter wildcards. Also, some letters can be excluded from the matching species Alpha codes. If no pattern is given, and no letters are excluded, then all of the possible BRDL answers will be displayed.

## Examples
### Display a single, matching BRDL solution
```
shell> brdlGuesser.pl -p BBMA
   1. BBMA: Black-billed Magpie
```

### Display BRDL solutions that match a pattern
```
shell> brdlGuesser.pl -p R**L
   1. RFBL: Red-flanked Bluetail
   2. RWBL: Red-winged Blackbird
   3. RUBL: Rusty Blackbird
```

### Display BRDL solutions that match a pattern but do not contain some letters
```
shell> brdlGuesser.pl -p G*A* -x MOS
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

### Display all possible BRDL solutions
```
shell> brdlGuesser.pl
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
