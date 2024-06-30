# TODO
## Current Bug
- [x] <s>the long binary data see ms to not be integrated in the merged registry
    Classic.reg Line 34 to 55</s>
- [x] <s>if a non existing Hive is used the value in it is integrated in the previous key</s>

## Solved in 2.0.4
- The long binary is now correctly integrated is was due to misshandling hex value
- The non existing hive problem is now solved by using a more lazy regex and checking at before adding the value for the more 