# MLMatrix
MLMatrix is almost like cmatrix, but with ML instead of C. Made with [Nim](https://nim-lang.org/).

## Why another Matrix?
We're actually creating a game that uses practically the same logic. This project provides a clean base for that other project, tba.

## Features
- Made with Nim, compilation takes maybe 2 seconds.
- Zero dependencies. Compilation is super easy. No need to install anything except Nim.
- Uses Unicode for classic movie symbols so a special font isn't needed.

## Installation
Installing is easy. Ensure Nim is installed. Then ...
```
git clone https://github.com/maddestlabs/mlmatrix/
nim c d:release mlmatrix.nim
```

## Usage
Enter `./mlmatrix -h` for help:
```
Matrix Rain Effect in Nim
Usage: mlmatrix [options]
Options:
  -l, --lead-color COLOR   Set the color of the leading character
                           (green, red, blue, yellow, cyan, magenta, white)
  -t, --trail-color COLOR  Set the color of the trailing characters
  -c, --charset CHARS      Use custom characters instead of default
                           Supports Unicode characters or keywords:
                            'basic'   - AVEIOBS013587
                            'lines'   - │║
                            'braille' - ⠭⠶⠠⠑⠊⠞⠙⠕⠗
                            'bubbles' - ·ᵒᴼ
                            'default' - ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ012345789Z:.=*+-<>¦
  -s, --speed MULTIPLIER   Set the speed multiplier (default: 2.0)
  -g, --glitch PERCENT     Set glitch frequency percentage (default: 2)
  -e, --eraser PERCENT     Set eraser frequency percentage (default: 0)
  -m, --max-trail PERCENT  Set maximum trail length as percentage of screen height (default: 100)
  -f, --frequency PERCENT  Set drop creation frequency (default: 100)
  -h, --help               Show this help message
```
