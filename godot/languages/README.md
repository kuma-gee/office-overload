# Language Packs

To add new word lists to this game, they need to be added next to the game file (.exe) in a
folder called `languages`. It needs to be a `.csv` file similar to the ones provided in
the DLC.

The following requirements need to be met for it to be valid:

- The file name cannot be more than 18 characters (excluding the extension `.csv`)
- Every group (WORK, EMAIL, ...) needs to have at least 10 words
- The WORK groups needs to have at least 10 words for each of the following
    - characters < 6 (EASY)
    - characters > 6 and < 9 (MEDIUM)
    - characters > 9 (HARD)

It is not recommended to use other characters than the alphabet as the game might not be
able to handle it correctly. It will only work if the character can be typed with one
button press.