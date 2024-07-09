/**
 *  KeyChord.ahk
 *  
 *  A class for writing key chords in AutoHotKey.
 *  Now combinations like "Ctrl+Win+d, x, u" are supported!
 *  
 *  @version 1.34
 *  @author Komrad Toast (komrad.toast@hotmail.com)
 *  @see https://autohotkey.com/boards/viewtopic.php?f=83&t=131037
 *  @license
 *  Copyright (c) 2024 Tyler J. Colby (Komrad Toast)
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 *  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 *  and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 *  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *  
**/

#Requires AutoHotkey v2.0

/**
 *  KeyChord class
 *  This class provides a way to map keys to commands or nested key Chords.
 *  It allows for executing commands or nested key Chords based on user input.
 *  
 *  ```ahk2
 *  sampleKeyChord := KeyChord(3)
 *  sampleNestedChord := KeyChord(3)
 *  
 *  sampleKeyChord.Add("c", Run.Bind("calc"))
 *  sampleKeyChord.Add("n", Run.Bind("notepad"))
 *  
 *  sampleKeyChord.Add("1", sampleNestedChord)
 *  sampleNestedChord.Add("p", Run.Bind("mspaint"))
 *  sampleNestedChord.Add("w", Run.Bind("wordpad"))
 *  
 *  ^#a::sampleKeyChord.Execute()
 *  ```
 *  
 *  @class KeyChord
 *  @constructor `KeyChord(defaultTimeout := 3)`
 *  @property {Map} chords Map of keys to commands.
 *  @property {Map} nestedChords Map of keys to nested KeyChord instances.
 *  @property {Map} wildcards Map of wildcard keys to commands.
 *  @property {Integer} defaultTimeout The default timeout (in seconds) for user input.
 *  @method `Add(key)`: `Void` Adds a new command or key chord.
 *  @method `Delete(key)`: `Void` Deletes a command or key chord.
 *  @method `Clear()`: `Void` Clears all keys, commands, and nested KeyChords.
 *  @method `Execute(timeout)`: `Void` Execute the keychord.
**/
class KeyChord
{
    /**
     * Represents an action that can be executed as part of a KeyChord.
     * 
     * An Action encapsulates a command and an optional condition that must be met in order to execute the command.
     * 
     * @class Action
     * @constructor `Action(command, condition := True)`
     * @property {Any} Command The command to be executed when the Action is executed.
     * @property {Boolean|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} Condition The condition that must be met in order to execute the command. Defaults to `True`.
     * @method `Execute()`: `Void` Executes the command if the condition is met.
     */
    class Action
    {
        /**
         * Initializes a new instance of the `Action` class.
         *
         * @param {Any} command The command to be executed when the Action is executed.
         * @param {Boolean|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} [condition=True] The condition that must be met in order to execute the command.
         */
        __New(command, condition := True)
        {
            this.Command   := command
            this.Condition := condition

            allowedCommands   := ["KeyChord", "String", "Integer", "Float", "Number", "Func", "BoundFunc", "Closure", "Enumerator"]
            allowedConditions := ["String", "Integer", "Float", "Number", "Func", "BoundFunc", "Closure", "Enumerator"]

            commandOK := False
            conditionOK := False

            for cmdType in allowedCommands
                if Type(this.Command) == cmdType
                    commandOK := True

            for conditionType in allowedConditions
                if Type(this.Condition) == conditionType
                    conditionOK := True

            if !commandOK
                throw ValueError("Command must be or evaluate to a KeyChord, String, Integer, Boolean, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Command: " Type(this.Command))

            if !conditionOK
                throw ValueError("Condition must be or evaluate to a String, Integer, Boolean, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Condition: " Type(this.Condition))
        }

        /**
         * Executes the action.
         * 
         * This method is responsible for evaluationg the condition of and thusly executing the command or nested key chord of a KeyChord.Action
         * 
         * @param {Integer} [timeout=this.defaultTimeout (3)] The timeout (in seconds) for user input. If not provided, the default timeout is used.
         * @returns {Void}
         */
        Execute(timeout)
        {
            /**
             * Evaluates a condition value and returns a boolean result.
             * 
             * Supports evaluating conditions of type Boolean, String, Integer, Float, Number, Func, BoundFunc, Closure, and Enumerator.
             * For Booleans, returns the value as-is.
             * For Strings, returns True if the string is not empty, False otherwise.
             * For Integers, Floats, and Numbers, returns True if the value is greater than 0, False otherwise.
             * For Funcs, BoundFuncs, Closures, and Enumerators, calls the value and recursively evaluates the result.
             * Throws a ValueError if the condition value is of an unsupported type.
             * 
             * @param {Boolean|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} value The condition value to evaluate.
             * @returns {Boolean} The evaluated boolean result of the condition.
             */
            EvaluateCondition(value)
            {
                switch Type(value)
                {
                    case "Boolean":
                        return ((value) ? True : False)
                    case "String":
                        return ((value != "") ? True : False)
                    case "Integer", "Float", "Number":
                        return ((value != 0) ? True : False)
                    case "Func", "BoundFunc", "Closure", "Enumerator":
                        return EvaluateCondition(value.Call())
                    default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                        throw ValueError("Condition must be or evaluate to a Boolean, String, Integer, Float, Number, Func, BoundFunc, Closure, or Enumerator", -1, "Condition: " Type(value))
                    
                    return unset ; This should never get reached
                }
            }

            ; Check if this.Condition evaluates to true, if so, execute this.Command in the proper manner for it's type
            if EvaluateCondition(this.Condition)
            {
                switch Type(this.Command)
                {
                    Case "KeyChord":
                        this.Command.Execute(timeout)
                        return
                    Case "Float":
                        Send(KeyChord.RoundToDecimalPlaces(this.Command))
                        return
                    Case "String", "Integer", "Boolean", "Number":
                        Send(this.Command)
                        return
                    Case "Func", "BoundFunc", "Closure", "Enumerator":
                        this.Command.Call()
                        return
                    Default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                        throw ValueError("Command must be a KeyChord, String, Integer, Boolean, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Command: " Type(this.Command))

                    return unset ; This should never get reached
                }
            }
        }
    }

    /**
     * Initializes a new instance of the KeyChord class with the specified default timeout.
     *
     * @param {Integer} defaultTimeout The default timeout in seconds for key chord input. Must be greater than 0.
     */
    __New(defaultTimeout := 3)
    {
        ; Map of keys to nested KeyChord instances
        this.nestedChords := Map()

        ; Map of keys to commands
        this.chords := Map()

        ; Map of wildcard keys to commands
        this.wildcards := Map()
        
        ; Check to make sure timeout is valid
        if (defaultTimeout > 0)
            this.defaultTimeout := defaultTimeout
        else
            throw ValueError("Timeout must be greater than 0", -1, Type(defaultTimeout) ": " defaultTimeout)
    }

    /**
     *  Gets user input from the keyboard.
     *  
     *  Gets an input from user, with optional timeout, length, case-sensitivity
     *  
     *  ```ahk2
     *  Switch GetUserInput(1)
     *  {
     *      Case "c":
     *          Run("calc")
     *      Case "+c":
     *          Run("notepad")
     *  }
     *  ```
     *  
     *  @param {Integer} timeout The timeout in seconds.
     *  @param {Integer} length The length of the input in characters.
     *  @param {Integer} caseSensitive Whether or not the input should be case-sensitive.
     *  
     *  @return {String} The user's input key strokes.
    **/
    GetUserInput(timeout := 0)
    {
        if (timeout <= 0)
            throw ValueError("Timeout must be greater than 0", -1, Type(timeout) ": " timeout)

        Suspend(True) ; Suspend the user's hotkeys, to avoid interference

        static specialKeys := ([ ; Make sure all special keys are handled
            "CapsLock"         , "Space"           , "Backspace"    , "Delete"         , "Up"                , "Down"         ,
            "Left"             , "Right"           , "Home"         , "End"            , "PgUp"              , "PgDn"         ,
            "Insert"           , "Tab"             , "Enter"        , "Esc"            , "ScrollLock"        , "AppsKey"      ,
            "PrintScreen"      , "CtrlBreak"       , "Pause"        , "Help"           , "Sleep"             , "Browser_Back" ,
            "Browser_Forward"  , "Browser_Refresh" , "Browser_Stop" , "Browser_Search" , "Browser_Favorites" , "Browser_Home" ,
            "Volume_Mute"      , "Volume_Up"       , "Volume_Down"  , "Media_Next"     , "Media_Prev"        , "Media_Stop"   ,
            "Media_Play_Pause" , "Launch_Mail"     , "Launch_Media" , "Launch_App1"    , "Launch_App2"       , "NumpadDot"    ,
            "NumpadDiv"        , "NumpadMult"      , "NumpadAdd"    , "NumpadSub"      , "NumpadEnter"       , "NumLock"      ,
            "NumpadIns"        , "NumpadEnd"       , "NumpadDown"   , "NumpadPgDn"     , "NumpadLeft"        , "NumpadClear"  ,
            "NumpadRight"      , "NumpadHome"      , "NumpadUp"     , "NumpadPgUp"     , "NumpadDel"         , "Numpad0"      ,
            "Numpad1"          , "Numpad2"         , "Numpad3"      , "Numpad4"        , "Numpad5"           , "Numpad6"      ,
            "Numpad7"          , "Numpad8"         , "Numpad9"      , "F1"             , "F2"                , "F3"           ,
            "F4"               , "F5"              , "F6"           , "F7"             , "F8"                , "F9"           ,
            "F10"              , "F11"             , "F12"          , "F13"            , "F14"               , "F15"          ,
            "F16"              , "F17"             , "F18"          , "F19"            , "F20"               , "F21"          ,
            "F22"              , "F23"             , "F24"          ,
        ])

        endKeys := ""
        for tempKey in specialKeys
        {
            tempKey := "{" tempKey "}"
            endKeys .= tempKey
        }

        key := InputHook("L1 T" timeout, endKeys) ; Create a one character input hook, with the timeout and endKeys passed by the user
        key.KeyOpt("{All}", "S")  ; Suppress all keys
        key.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "N") ; Allow detection of modifiers by causing OnKeyUp and OnKeyDown to be called
        key.Start()

        ; Check to see if the user pressed any keys
        if !key.Wait()
        {
            MsgBox("Input timed out or failed.`nTimeout: " timeout, "Error")
            Return ""
        }

        ; We only need to worry about these 8 modifiers, since the "sided" vs "non-sided"
        ; key strings are detected and handled in the KeyChord.Execute() function.
        modifiers := ""
        modKeys := [
            ["LCtrl" , "<^"], ["RCtrl" , ">^"],
            ["LAlt"  , "<!"], ["RAlt"  , ">!"],
            ["LShift", "<+"], ["RShift", ">+"],
            ["LWin"  , "<#"], ["RWin"  , ">#"]]

        ; Check to see if any of the modifiers are pressed,
        ; if they are, add them to the modifiers string.
        for key in modKeys
        {
            if GetKeyState(key[1], "P")
                modifiers .= key[2]
        }

        Suspend(False) ; Resume the user's hotkeys

        ; If not a special key, return the input, plus modifiers
        input := (key.Input ? key.Input : key.EndKey)
        return modifiers . input
    }

    /**
     *  Function to create and bind key chords from a Map of key-command bindings.
     *  
     *  
     *  ```ahk2
     *  ; Create a Map of key-command bindings
     *  appBindings := {
     *      "1": 1,                                        ; {Integer}   1
     *      "f": 43.54,                                    ; {Float}     43.54
     *      "s": "Hello World",                            ; {String}    "Hello World"
     *      "b": True,                                     ; {Boolean}   True
     *      "c": Run.Bind("calc"),                         ; {BoundFunc} Calculator
     *      "n": Run.Bind("notepad"),                      ; {BoundFunc} Notepad
     *      "w": Run.Bind("wordpad"),                      ; {BoundFunc} Wordpad
     *      "p": Run.Bind("mspaint"),                      ; {BoundFunc} Paint
     *      "t": () => ( Send("^c"), MsgBox(A_Clipboard) ) ; {Func}
     *  }
     *  
     *  ; Create a new KeyChord instance and assign it to the appKeyChord variable
     *  ; Uses the static function CreateFromMap() to create the KeyChord.
     *  ; `timeout` is optional, the default value is `3` seconds.
     *  appKeyChord := KeyChord.CreateFromMap(2, appBindings)
     *  
     *  ^#1::appKeyChord.Execute() ; execute the key chord
     *  ```
     *  
     *  @param {Integer} timeout The timeout in seconds.
     *  @param {Map} bindingsMap A Map of key-command bindings.
     *  
     *  @return {KeyChord} A new KeyChord instance.
    **/ 
    static CreateFromMap(timeout, bindingsMap)
    {
        if (timeout <= 0)
            throw ValueError("Timeout must be greater than 0", -1, Type(timeout) ": " timeout)

        this.keyChord := KeyChord(timeout)

        for key, action in bindingsMap
        {
            if action is KeyChord.Action
                this.keyChord.Add(key, action)
            else if IsObject(action) && action.HasOwnProp("Command")
                this.keyChord.Add(key, KeyChord.Action(action.Command,
                    action.HasOwnProp("Condition") ? action.Condition : True))
            else
                this.keyChord.Add(key, KeyChord.Action(action))
        }

        return this.keyChord
    }

    /**
     *  Add a key-command mapping or a nested key Chord.
     *  @param {String} key The key to map
     *  @param {String|Integer|Float|BoundFunc|KeyChord} command - The command or nested key Chord to map
     *  @returns {Void}
    **/
    Add(key, action)
    {
        if !(action is KeyChord.Action)
            action := KeyChord.Action(action)

        if (InStr(key, "*") || InStr(key, "?") || InStr(key, "-"))
            this.wildcards.Set(key, action)
        else if IsObject(action.Command) && (Type(action.Command) == "KeyChord")
            this.nestedChords.Set(key, action)
        else
            this.chords.Set(key, action)
    }

    /**
     *  Remove a key-command mapping or a nested key Chord.
     *  @param {String} key The key to remove
     *  @returns {Void}
    **/
    Remove(key)
    {
        if this.chords.Has(key)
            this.chords.Delete(key)
        else if this.nestedChords.Has(key)
            this.nestedChords.Delete(key)
        else if this.wildcards.Has(key)
            this.wildcards.Delete(key)
        else
            MsgBox("Key not found: " key "`n`nPlease make sure the key is mapped correctly.`n`nExample:`nexampleKeyChord.Add(`"" key "`", Run.Bind(`"notepad`"))", "Error")
    }

    /**
     *  Update a key-command mapping or a nested key Chord.
     *  @param {String} key The key to update.
     *  @param {String|Integer|Float|BoundFunc|KeyChord} newCommand - The new command or nested key Chord.
     *  @returns {Void}
    **/
    Update(key, newAction)
    {
        if !(newAction is KeyChord.Action)
            newAction := KeyChord.Action(newAction)

        if this.chords.Has(key)
            this.chords.Set(key, newAction)
        else if this.nestedChords.Has(key)
            this.nestedChords.Set(key, newAction)
        else if this.wildcards.Has(key)
            this.wildcards.Set(key, newAction)
        else
            MsgBox("Key not found: " key "`n`nPlease make sure the key is mapped correctly.`n`nExample:`nexampleKeyChord.Add(`"" key "`", Run.Bind(`"notepad`"))", "Error")
    }

    /**
     *  Clear all key-command mappings and nested key Chords.
     *  @returns {Void}
    **/
    Clear()
    {
        this.chords.Clear()
        this.nestedChords.Clear()
    }

    /**
     *  Execute the command or nested key Chord mapped to the user input.
     *  @param {Integer} timeout The timeout (in seconds) for user input.
     *  @returns {Void}
    **/
    Execute(timeout := this.defaultTimeout)
    {
        keyString := ""
        for key in this.chords
        {
            if (A_Index > 1)
                keyString .= ", "
            keyString .= key
        }

        ToolTip("Press a key...`n" keyString)
        this.key := this.GetUserInput(timeout)
        TimedToolTip(this.key, 1)

        if (this.key == "")
        {
            TimedToolTip("Error: No input received.", 1)
        }
        else
        {
            unsidedKey := RegExReplace(this.key, "(<|>)*", "")

            if this.chords.Has(this.key) || this.chords.Has(unsidedKey)
            {
                action := this.chords.Get(this.key)
                action.Execute(timeout)
                return
            }
            else if this.nestedChords.Has(this.key) || this.nestedChords.Has(unsidedKey)
            {
                action := this.nestedChords.Get(this.key)
                action.Execute(timeout)
                return
            }
            else
            {
                for pattern, action in this.wildcards
                {
                    if (this.MatchWildcard(pattern, this.key) || this.MatchWildcard(pattern, unsidedKey))
                    {
                        action.Execute(timeout)
                        return
                    }
                }
            }

            TimedToolTip("Key not found: " this.key, 5)
        }

        return
    }

    /**
     *  Rounds a float to the number of decimal places it has.
     *  Used for returning exactly the float that was typed,
     *  instead of a slightly different value. I can't get rid of
     *  the trailing zeroes, however. Help would be appreciated there.
     *  @param {Float} value The float value to round.
     *  @returns {Float} The rounded float value.
    **/
    RoundToDecimalPlaces(value)
    {
        strValue := Format("{:f}", value)
        decimalPos := InStr(strValue, ".")
        if (decimalPos)
        {
            decimalPlaces := StrLen(SubStr(strValue, decimalPos + 1))
            return Round(value, decimalPlaces)
        }
        return value
    }

    /**
     *  Displays a tooltip for a user-defined amount of seconds
     *  @param text {String} The text to display in the tooltip.
     *  @param {Integer} duration The duration (in seconds) of the tooltip.
    **/
    TimedToolTip(text, duration := 3)
    {
        duration := 1000 * duration

        ToolTip(text)
        SetTimer () => ToolTip(), -(duration)
    }

    /**
     *  Match the given input string against the given wildcard pattern.
     *  @param {String} pattern The wildcard pattern to match against.
     *  @param {String} input The input string to match against the pattern.
     *  @returns {Boolean} True if the input string matches the pattern, false otherwise.
    **/
    MatchWildcard(pattern, input)
    {
        if (pattern == input)
            return true

        ; Handle modifiers
        patternModifiers := ""
        inputModifiers := ""
        if (RegExMatch(pattern, "^[!^+#<>]*"))
        {
            patternModifiers := RegExReplace(pattern, "^([!^+#<>]*)(.*)", "$1")
            pattern := RegExReplace(pattern, "^([!^+#<>]*)(.*)", "$2")
            inputModifiers := RegExReplace(input, "^([!^+#<>]*)(.*)", "$1")
            input := RegExReplace(input, "^([!^+#<>]*)(.*)", "$2")
        }

        ; Escape special regex characters except * and ?
        pattern := RegExReplace(pattern, "([\\.\^$+\[\]\(\)\{\}|])", "\$1")

        if (InStr(pattern, "*") || InStr(pattern, "?"))
        {
            pattern := StrReplace(pattern, "*", ".*")
            pattern := StrReplace(pattern, "?", ".")
            return this.MatchModifiers(patternModifiers, inputModifiers) && RegExMatch(input, "^" . pattern . "$")
        }

        if (InStr(pattern, "-"))
        {
            parts := StrSplit(pattern, "-")
            if (parts.Length == 2)
            {
                start := Ord(parts[1])
                end := Ord(parts[2])
                inputChar := Ord(input)
                return this.MatchModifiers(patternModifiers, inputModifiers) && (inputChar >= start && inputChar <= end)
            }
        }

        return false
    }

    /**
     * Compares the pattern modifiers and input modifiers to ensure they match.
     * @param {String} patternMods The modifiers from the pattern.
     * @param {String} inputMods The modifiers from the input.
     * @returns {Boolean} True if the modifiers match, false otherwise.
     */
    MatchModifiers(patternMods, inputMods)
    {
        ; If pattern has no sided modifiers, ignore sides in input
        if (!RegExMatch(patternMods, "[<>]"))
        {
            patternMods := RegExReplace(patternMods, "[<>]", "")
            inputMods := RegExReplace(inputMods, "[<>]", "")
        }

        ; Sort modifiers to ensure consistent order
        patternMods := Sort(patternMods)
        inputMods := Sort(inputMods)

        return (patternMods == inputMods)
    }
}