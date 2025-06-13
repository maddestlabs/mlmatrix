# MLMatrix
MLMatrix is almost like [cmatrix](https://github.com/abishekvashok/cmatrix), but made in [Nim](https://nim-lang.org/) with lots of help from ML (Machine Learning, or AI). Specifically, [Claude](https://claude.ai/new) was used to write the initial code and then, for troubleshooting and adding features.

Try it out and and easily configure it via JavaScript (converted via Claude): [Web version](https://maddestlabs.github.io/mlmatrix/)

Check out the intro video:
[![MLMatrix | Matrix raining code for the terminal](https://img.youtube.com/vi/OCjeoTUsjFg/maxresdefault.jpg)](https://youtu.be/ajy2HMS3IYE)

Example of MLMatrix in Windows Terminal using [Apocalypse CRT](https://github.com/maddestlabs/apocalypse-crt) shader:
[![Apocalypse CRT in Windows Terminal](https://raw.githubusercontent.com/maddestlabs/apocalypse-crt/refs/heads/main/screenshots/apocalypse-crt-mlmatrix.jpg 'Apocalypse CRT')](https://youtu.be/ajy2HMS3IYE)

## Why another Matrix?
We're actually creating a game that uses similar logic. This project provides a clean base for that other project, TBA. We also wanted a version of cmatrix with custom character support, one that's just as easily available (cmatrix is probably in every Linux distro) but without needing to add a repo. Nim makes that possible. Nim compilation is practically as fast as installing an app from a custom repo.

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
This will generate the executable.

## Usage
Enter `./mlmatrix` to run the executable.  
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

The `-c` or `--charset` option lets you provide your own characters.  

For example, for binary rain:
`./mlmatrix -c 01`
