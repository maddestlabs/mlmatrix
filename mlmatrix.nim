import terminal, random, os, unicode, strutils, times

type
  Color = enum
    Green, Red, Blue, Yellow, Cyan, Magenta, White

  Drop = object
    x, y: int           # Position
    length: int         # Length of the trail
    speed: float        # Speed multiplier
    char: string        # Current character - only head changes
    trailChars: seq[string]  # Historical characters for the trail
    glitchChars: seq[string] # Characters displayed during glitch
    glitchActive: seq[bool]  # Which positions are currently glitching
    trailPos: int       # Current position in the trail array (circular buffer)
    isDead: bool        # Flag to indicate if the drop should be removed
    lastUpdate: float   # Time of last update
    lastGlitchCheck: float # Time of last glitch effect check
    hasEraser: bool     # Flag to indicate if this drop has an eraser following it

  # New type for eraser drops that follow behind and clear the screen
  EraserDrop = object
    x, y: int           # Position
    speed: float        # Speed multiplier (usually matches the parent drop's speed)
    isDead: bool        # Flag to indicate if the eraser should be removed
    lastUpdate: float   # Time of last update

  Buffer = object
    width, height: int
    data: seq[seq[tuple[ch: string, fg, bg: int, bright: bool]]]

  Config = object
    leadColor: Color
    trailColor: Color
    charset: string
    speedMultiplier: float
    glitchFrequency: int   # Percentage chance (0-100) of glitch occurrence
    eraserChance: int      # Percentage chance (0-100) of drops having erasers
    maxTrailPercent: int   # Maximum trail length as percentage of screen height
    dropFrequency: int     # Percentage chance (0-100) of creating new drops

const
  BasicChars = "AVEIOBS013587"
  LinesChars = "│║"
  BrailleChars = "⠭⠶⠠⠑⠊⠞⠙⠕⠗"
  BubblesChars = "·ᵒᴼ"
  DefaultChars = "ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ012345789Z:.=*+-<>¦"

# Convert Color enum to terminal color code
proc toTerminalColor(color: Color): ForegroundColor =
  case color
  of Green: fgGreen
  of Red: fgRed
  of Blue: fgBlue
  of Yellow: fgYellow
  of Cyan: fgCyan
  of Magenta: fgMagenta
  of White: fgWhite

# Parse command line arguments
proc parseArgs(): Config =
  result = Config(
    leadColor: Green,
    trailColor: Green,
    charset: "",  # Empty means use default
    speedMultiplier: 2.0,
    glitchFrequency: 2,  # Default 2% glitch chance
    eraserChance: 0,   # Default 0% chance for a drop to have an eraser
    maxTrailPercent: 100, # Default max trail length is 100% of screen height
    dropFrequency: 100     # Default 100% chance to create drops
  )
  
  var i = 1
  while i < paramCount() + 1:
    let param = paramStr(i)
    case param
    of "-h", "--help":
      echo "Matrix Rain Effect in Nim"
      echo "Usage: mlmatrix [options]"
      echo "Options:"
      echo "  -l, --lead-color COLOR   Set the color of the leading character"
      echo "                           (green, red, blue, yellow, cyan, magenta, white)"
      echo "  -t, --trail-color COLOR  Set the color of the trailing characters"
      echo "  -c, --charset CHARS      Use custom characters instead of default"
      echo "                           Supports Unicode characters or keywords:"
      echo "                            'basic'   - " & BasicChars
      echo "                            'lines'   - " & LinesChars
      echo "                            'braille' - " & BrailleChars
      echo "                            'bubbles' - " & BubblesChars
      echo "                            'default' - " & DefaultChars
      echo "  -s, --speed MULTIPLIER   Set the speed multiplier (default: 2.0)"
      echo "  -g, --glitch PERCENT     Set glitch frequency percentage (default: 2)"
      echo "  -e, --eraser PERCENT     Set eraser frequency percentage (default: 0)"
      echo "  -m, --max-trail PERCENT  Set maximum trail length as percentage of screen height (default: 100)"
      echo "  -f, --frequency PERCENT  Set drop creation frequency (default: 100)"
      echo "  -h, --help               Show this help message"
      quit(0)
    of "-l", "--lead-color":
      if i + 1 < paramCount() + 1:
        inc i
        let colorName = paramStr(i).toLower()
        result.leadColor = case colorName
          of "green": Green
          of "red": Red
          of "blue": Blue
          of "yellow": Yellow
          of "cyan": Cyan
          of "magenta": Magenta
          of "white": White
          else: Green
    of "-t", "--trail-color":
      if i + 1 < paramCount() + 1:
        inc i
        let colorName = paramStr(i).toLower()
        result.trailColor = case colorName
          of "green": Green
          of "red": Red
          of "blue": Blue
          of "yellow": Yellow
          of "cyan": Cyan
          of "magenta": Magenta
          of "white": White
          else: Green
    of "-c", "--charset":
      if i + 1 < paramCount() + 1:
        inc i
        let charsetArg = paramStr(i).strip().toLower()
        
        # Check if it's one of our predefined keywords
        result.charset = case charsetArg
          of "basic": BasicChars
          of "lines": LinesChars
          of "braille": BrailleChars
          of "bubbles": BubblesChars
          of "default": DefaultChars
          else: paramStr(i).strip()  # Use the provided characters directly
    of "-s", "--speed":
      if i + 1 < paramCount() + 1:
        inc i
        try:
          result.speedMultiplier = parseFloat(paramStr(i))
        except ValueError:
          result.speedMultiplier = 1.0
    of "-g", "--glitch":
      if i + 1 < paramCount() + 1:
        inc i
        try:
          result.glitchFrequency = parseInt(paramStr(i)).clamp(0, 100)
        except ValueError:
          result.glitchFrequency = 2
    of "-e", "--eraser":
      if i + 1 < paramCount() + 1:
        inc i
        try:
          result.eraserChance = parseInt(paramStr(i)).clamp(0, 100)
        except ValueError:
          result.eraserChance = 100
    of "-m", "--max-trail":
      if i + 1 < paramCount() + 1:
        inc i
        try:
          result.maxTrailPercent = parseInt(paramStr(i)).clamp(1, 100)
        except ValueError:
          result.maxTrailPercent = 25
    of "-f", "--frequency":
      if i + 1 < paramCount() + 1:
        inc i
        try:
          result.dropFrequency = parseInt(paramStr(i)).clamp(0, 100)
        except ValueError:
          result.dropFrequency = 50
    else:
      discard
    inc i

# Generate a random matrix character
proc matrixChar(charset: string): string =
  # Default to DefaultChars if no charset provided
  let charsToUse = if charset.len > 0: charset else: DefaultChars
  
  # Handle as Unicode characters
  let runes = toRunes(charsToUse)
  let runeIndex = rand(runes.len - 1)
  result = $runes[runeIndex]
      
  # Additional safety check to filter out any potentially problematic characters
  if result == "\r" or result == "\n" or result == "\t" or result == "\b":
    result = "+"

# Initialize a new drop
proc newDrop(x: int, height: int, config: Config): Drop =
  # Calculate maximum trail length based on screen height percentage
  let max_length = max(5, (height * config.maxTrailPercent) div 100)
  let length = rand(5..max_length)  # Random trail length between 5 and max_length
  var 
    trailChars = newSeq[string](length)
    glitchChars = newSeq[string](length)
    glitchActive = newSeq[bool](length)
  
  # Initialize trail with empty chars (they'll be filled as the drop moves)
  for i in 0..<length:
    trailChars[i] = " "
    glitchChars[i] = " "
    glitchActive[i] = false
  
  # Determine if this drop will have an eraser
  let hasEraser = rand(100) < config.eraserChance
  
  result = Drop(
    x: x,
    y: 0,
    length: length,
    speed: (rand(0.5..1.5) * config.speedMultiplier),
    char: matrixChar(config.charset),
    trailChars: trailChars,
    glitchChars: glitchChars,
    glitchActive: glitchActive,
    trailPos: 0,
    isDead: false,
    lastUpdate: epochTime(),
    lastGlitchCheck: epochTime(),
    hasEraser: hasEraser
  )

# Initialize a new eraser drop that follows a main drop
proc newEraserDrop(drop: Drop): EraserDrop =
  # Start eraser at a random position behind the main drop
  let followDistance = rand(drop.length + 5..drop.length + 15)  # Follow at a visible distance
  
  result = EraserDrop(
    x: drop.x,
    y: max(0, drop.y - followDistance),  # Ensure y doesn't go negative
    speed: drop.speed * 0.95,  # Just slightly slower than the main drop
    isDead: false,
    lastUpdate: epochTime()
  )

# Update the drop's position
proc update(drop: var Drop, height: int, now: float, config: Config): bool =
  var updated = false
  
  # Update position if enough time has passed based on speed
  if now - drop.lastUpdate >= (1.0 / (10.0 * drop.speed)):
    drop.lastUpdate = now
    
    # Store the current head character in the trail before changing it
    drop.trailChars[drop.trailPos] = drop.char
    drop.trailPos = (drop.trailPos + 1) mod drop.length
    
    drop.y += 1
    
    # Generate a new head character
    drop.char = matrixChar(config.charset)
    
    # Check if the drop has moved off the bottom of the screen
    if drop.y - drop.length > height:
      drop.isDead = true
      
    updated = true
  
  # Update glitch effects - independent of position updates
  if now - drop.lastGlitchCheck >= 0.1:  # Check for glitches every 100ms
    drop.lastGlitchCheck = now
    
    # Random chance for each position in the trail to start glitching
    for i in 0..<drop.length:
      # If not already glitching, small chance to start
      if not drop.glitchActive[i] and rand(100) < config.glitchFrequency:
        drop.glitchActive[i] = true
        drop.glitchChars[i] = matrixChar(config.charset)
      # If currently glitching, high chance to stop
      elif drop.glitchActive[i] and rand(100) < 40:  # 40% chance to stop
        drop.glitchActive[i] = false
  
  return updated

# Update the eraser drop's position
proc update(eraser: var EraserDrop, height: int, now: float): bool =
  var updated = false
  
  # Update position if enough time has passed based on speed
  if now - eraser.lastUpdate >= (1.0 / (10.0 * eraser.speed)):
    eraser.lastUpdate = now
    eraser.y += 1
    
    # Check if the eraser has moved off the bottom of the screen
    if eraser.y > height:
      eraser.isDead = true
      
    updated = true
  
  return updated

# Create a new buffer
proc newBuffer(width, height: int): Buffer =
  result = Buffer(
    width: width,
    height: height,
    data: newSeq[seq[tuple[ch: string, fg, bg: int, bright: bool]]](height)
  )
  
  for y in 0..<height:
    result.data[y] = newSeq[tuple[ch: string, fg, bg: int, bright: bool]](width)
    for x in 0..<width:
      result.data[y][x] = (ch: " ", fg: 0, bg: 0, bright: false)

# Clear the buffer
proc clear(buffer: var Buffer) =
  for y in 0..<buffer.height:
    for x in 0..<buffer.width:
      buffer.data[y][x] = (ch: " ", fg: 0, bg: 0, bright: false)

# Draw a drop to the buffer
proc draw(drop: Drop, buffer: var Buffer, config: Config) =
  let headY = drop.y
  let leadColor = config.leadColor.ord
  let trailColor = config.trailColor.ord
  
  # Draw the head of the drop
  if headY >= 0 and headY < buffer.height and drop.x < buffer.width:
    buffer.data[headY][drop.x] = (ch: drop.char, fg: leadColor, bg: 0, bright: true)
  
  # Draw the trail (using historical characters)
  for i in 0..<drop.length:
    let y = headY - i - 1
    if y >= 0 and y < buffer.height and drop.x < buffer.width:
      # Calculate the index in the circular buffer
      let trailIndex = (drop.trailPos - 1 - i + drop.length) mod drop.length
      
      # Determine which character to show (glitched or normal)
      var trailChar: string
      if drop.glitchActive[trailIndex]:
        trailChar = drop.glitchChars[trailIndex]
      else:
        trailChar = drop.trailChars[trailIndex]
      
      # Only draw if we have a character (avoid empty spaces from initialization)
      if trailChar != " ":
        buffer.data[y][drop.x] = (
          ch: trailChar,
          fg: trailColor, 
          bg: 0, 
          bright: i < 1  # First few trail characters are bright, regardless of glitch state
        )

# Draw an eraser drop to the buffer (simply drawing spaces)
proc draw(eraser: EraserDrop, buffer: var Buffer) =
  let y = eraser.y
  
  # Draw the eraser (simply a space character)
  if y >= 0 and y < buffer.height and eraser.x < buffer.width:
    # Explicitly clear the cell by setting it to a space
    buffer.data[y][eraser.x] = (ch: " ", fg: 0, bg: 0, bright: false)

# Render the buffer to the terminal
proc render(buffer: Buffer) =
  setCursorPos(0, 0)
  
  # Safety to prevent screen scrolling
  let renderHeight = min(buffer.height, terminalHeight())
  
  for y in 0..<renderHeight:
    for x in 0..<min(buffer.width, terminalWidth()):
      let cell = buffer.data[y][x]
      # Also render spaces to properly clear characters
      setCursorPos(x, y)
      if cell.ch == " ":
        # Just write a space with default attributes
        resetAttributes()
        stdout.write(" ")
      else:
        let termColor = toTerminalColor(Color(cell.fg))
        if cell.bright:
          setForegroundColor(termColor, true)
        else:
          setForegroundColor(termColor, false)
          setStyle({styleDim})
        stdout.write(cell.ch)
  
  flushFile(stdout)
  resetAttributes()

proc main() =
  # Parse command line arguments
  let config = parseArgs()
  
  # Set up terminal and exit handler
  hideCursor()
  
  # Simply restore cursor on exit instead of trying to restore terminal modes
  setControlCHook(proc() {.noconv.} =
    resetAttributes()
    showCursor()
    eraseScreen()
    quit(0)
  )
  
  randomize()
  
  # Get initial terminal dimensions
  var width, height: int
  try:
    (width, height) = terminalSize()
  except:
    width = 80
    height = 24
  
  # Create double buffers
  var 
    frontBuffer = newBuffer(width, height)
    backBuffer = newBuffer(width, height)
    drops = newSeq[Drop]()
    erasers = newSeq[EraserDrop]()  # New collection for eraser drops
    lastResizeCheck = epochTime()
  
  # Main loop
  while true:
    let now = epochTime()
    
    # Check for terminal resize (not too often)
    if now - lastResizeCheck > 0.5:
      try:
        let (newWidth, newHeight) = terminalSize()
        if newWidth != width or newHeight != height:
          width = newWidth
          height = newHeight
          frontBuffer = newBuffer(width, height)
          backBuffer = newBuffer(width, height)
          eraseScreen()
      except:
        discard
      lastResizeCheck = now
    
    # Clear the back buffer
    backBuffer.clear()
    
    # Update and draw drops
    var i = 0
    while i < drops.len:
      let updated = drops[i].update(height, now, config)
      
      # If the drop has moved far enough and has no eraser yet but should have one,
      # create an eraser drop for it
      if drops[i].hasEraser and drops[i].y > 20:  # Wait until the drop has moved down a bit
        # Create an eraser drop that follows this drop
        erasers.add(newEraserDrop(drops[i]))
        # Mark that we've created the eraser
        drops[i].hasEraser = false
      
      drops[i].draw(backBuffer, config)
      
      if drops[i].isDead:
        drops.delete(i)
      else:
        inc i
    
    # Update and draw eraser drops
    i = 0
    while i < erasers.len:
      let updated = erasers[i].update(height, now)
      erasers[i].draw(backBuffer)
      
      if erasers[i].isDead:
        erasers.delete(i)
      else:
        inc i
    
    # Create new drops based on user-configurable frequency
    for x in 0..<width:
      if rand(100) < config.dropFrequency:  # Now using the configurable parameter
        let existingDrop = (proc(): bool =
          for drop in drops:
            if drop.x == x:
              return true
          return false
        )()
        
        if not existingDrop:
          drops.add(newDrop(x, height, config))
    
    # Swap buffers and render
    swap(frontBuffer, backBuffer)
    render(frontBuffer)
    
    # Control frame rate
    sleep(30)

when isMainModule:
  main()
