# BrdlGuesser
## Description
Guess the possible BRDL answers given an optional pattern as a starting point. Use one or more asterisks (`*`) as single-letter wildcards. If no pattern is given, all possible BRDL answers will be displayed.

## Examples
### Display a single, matching BRDL solution
```
shell> brdlGuesser.pl BBMA
   1. BBMA: Black-billed Magpie
```

### Display BRDL solutions that match a pattern
```
shell> brdlGuesser.pl R**L
   1. RFBL: Red-flanked Bluetail
   2. RWBL: Red-winged Blackbird
   3. RUBL: Rusty Blackbird
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
```
