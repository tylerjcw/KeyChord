# KeyChord Class for AutoHotKey v2

## Summary & Examples
KeyChord is an AutoHotKey v2 class for writing key chords (key sequences, key chains, whatever you wanna call them).

In short, It allows hitting a chain "initiator" (usually just a regular hotkey), then hitting another key
(or a sequence of keys), and having an action happen depending on which key was pressed. Here is an example:
```
#Include "KeyChord.ahk"

; Initiate a new empty KeyChord. The default timeout is 3, but we are changing it to 2 here.
KeyChord := KeyChord(2)

; Add the hotkeys to the KeyChord.
; If you are calling a function, you have to call FunctionName.Bind(arg1, arg2, ...)
exampleKeyChord.Add("1", "example_email@somewhere.com")
exampleKeyChord.Add("c", Run.Bind("calc"))                                           ; Calculator
exampleKeyChord.Add("n", Run.Bind("notepad"))                                        ; Notepad
exampleKeyChord.Add("w", Run.Bind("wordpad"))                                        ; WordPad
exampleKeyChord.Add("p", Run.Bind("mspaint"))                                        ; Paint
exampleKeyChord.Add("f", Run.Bind("shell:::{20D04FE0-3AEA-1069-A2D8-08002B30309D}")) ; This PC

; Bind the KeyChord to a hotkey.
^#a::exampleKeyChord.Execute()
```
In the example above, if the user presses "Ctrl+Win+a" and then presses "1", "n", "c", "w", or "f", the appropriate
action associated with that key will happen. So "1" will send the String value "example_email@somewhere.com". "n" will
run Notepad, "c" will run Calculator, "w" will run WordPad, and "f" will open "This PC".

KeyChords can also be added to other KeyChords, allowing for recursion, and longer key sequences. Take the following, for example:
```
#Include "KeyChord.ahk"

; We'll create a new KeyChord, we'll leave the timeout at the default (3 seconds)
nestedKeyChord := KeyChord()

; Add the hotkeys
nestedKeyChord.Add("g", Run.Bind("https://www.google.com/"))
nestedKeyChord.Add("b", Run.Bind("https://www.bing.com/"))
nestedKeyChord.Add("a", Run.Bind("https://www.autohotkey.com/"))

; Then we will add the new KeyChord to our original keychord, bound to the "k" key.
exampleKeyChord.Add("k", nestedKeyChord)
```
Now, "Ctrl+Win+a, then k (within 2 seconds), then g (within 3 seconds)" will Open Google, and so on down the list of hotkeys.

In update `1.3`, the `KeyChord.CreateFromMap()` function was added, which allows for KeyChord declarations like the following:
```
#Include "KeyChord.ahk"

; Create a new KeyChord from a map.
; The map is a dictionary of key sequences, and the values are the actions to be performed.
exampleKeyChord := KeyChord.CreateFromMap(3, Map(
    "1", "example_email@somewhere.com",
    "c", Run.Bind("calc"),                                ; Calculator
    "n", Run.Bind("notepad"),                             ; Notepad
    "w", Run.Bind("wordpad"),                             ; Wordpad
    "p", Run.Bind("mspaint"),                             ; Paint
    "f", Run.Bind("shell:::{20D04FE0-3AEA-1069-A2D8-08002B30309D}") ; This PC
))

^#a::exampleKeyChord.Execute()
```

The `KeyChord.CreateFromMap()` function takes an integer as a timeout value (in seconds), then a map of "key - command" values.
With this function, and KeyChord recursion, you can declare nested KeyChords with a more natural syntax, like this:
```
#Include "KeyChord.ahk"

^#a::KeyChord.CreateFromMap(3, Map(
    "1", "example_email@somewhere.com",
    "c", Run.Bind("calc"),                                           ; Calculator
    "n", Run.Bind("notepad"),                                        ; Notepad
    "w", Run.Bind("wordpad"),                                        ; Wordpad
    "p", Run.Bind("mspaint"),                                        ; Paint
    "f", Run.Bind("shell:::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"), ; This PC
    "k", KeyChord.CreateFromMap(3, Map(
        "g", Run.Bind("https://www.google.com/"),                    ; Google
        "b", Run.Bind("https://www.bing.com/"),                      ; Bing
        "a", Run.Bind("https://www.autohotkey.com/")                 ; AutoHotKey
    ))
)).Execute()
```

And here's a more complex example, using the `KeyChord.CreateFromMap()` function (from my own config):
```
^#r::KeyChord.CreateFromMap(3, Map(                 ; Ctrl+Win+r
    "m", Rainmeter.Bind("!Manage"),                 ;     m - Open Rainmeter management interface.
    "r", Rainmeter.Bind("!RefreshApp"),             ;     r - Refresh all
    "t", KeyChord.CreateFromMap(3, Map(             ;     t - Toggles (Nested KeyChord)
        "a", RainMeter.Bind("!Toggle"),             ;         a - Toggle all
        "b", ToggleMeter.Bind("MeterBackground"),   ;         b - Toggle background meter
        "w", KeyChord.CreateFromMap(3, Map(         ;         w - Weather Toggles (Nested KeyChord)
            "a", ToggleGroup.Bind("Weather"),       ;             a - Toggle all weather skins
            "s", ToggleGroup.Bind("SimpleWeather"), ;             s - Toggle SimpleWeather skins
            "t", ToggleGroup.Bind("TinyWeather")    ;             t - Toggle TinyWeather skins
        )),                                         ;
    )),                                             ; Note: A three second timeout is used for all
)).Execute()                                        ; three of the KeyChord instances above.
```
## Class Outline

- `Add(key, command)`
  - Add a key-command mapping or a nested key Chord.
  - `key` : `{String}` => The key that will activate the command
  - `command` : `{Integer} | {Float} | {Boolean} | {String} | {BoundFunc} | {KeyChord}` => The command to execute when the key is pressed.

- `Remove(key)`
  - Remove a key-command mapping.
  - `key` : `{String}` => The key of the key-command mapping to be removed.

- `Update(key, newCommand)`
  - Update a key-command mapping with a new command.
  - `key` : `{String}` => The key of the key-command mapping to be updated.
  - `newCommand` : `{Integer} | {Float} | {Boolean} | {String} | {BoundFunc} | {KeyChord}` => The new command to be executed when the key is pressed.

- `Clear()`
  - Clears the KeyChord completely of all key-command bindings.

- `Execute(timeout := 3)`
  - Execute the command or nested key Chord mapped to the user input.
  - `timeout` : `{Integer}` => The timeout value (in seconds) for the key chord. Default := 3.

- `static CreateFromMap(timeout, map)`
  - Function to create and bind key chords from a Map of key-command bindings.
  - `timeout` : `{Integer}` => The timeout value (in seconds) for the key chord.
  - `map` : `{Map}` => The map of key-command bindings.