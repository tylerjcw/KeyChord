# KeyChord

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

exampleKeyChord := KeyChord.CreateFromMap(3, Map(
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
))

^#a::exampleKeyChord.Execute()
```

**Class Outline
-`Add()`
  _ `Execute()`