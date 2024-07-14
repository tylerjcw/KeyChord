/**
 *  KeyChord.ahk
 *  
 *  A class for writing key chords in AutoHotKey.
 *  Now combinations like "Ctrl+Win+d, x, u" are supported!
 *  
 *  @version 1.35
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
 *  @constructor `KeyChord(timeout?)`
 *  @property {Integer} [Timeout=3] The default timeout (in seconds) for user input..
 *  @method `Execute()`: `Void` Execute the keychord.
**/
class KeyChord extends Map
{
    ; Timeout value for user input before the InputHook stops listening for key presses.
    Timeout := 3 ; Change this to change the default timeout value of all newly created KeyChords (value is in seconds)

    ; If True, displays a helpful Key Reminder Message box when the InputHook times out.
    RemindKeys := True ; Set to False to have descriptive key reminder Message boxes OFF by default

    /**
     *  Initializes a new instance of the KeyChord class with the specified timeout (default 3 seconds).
     *  @param {Integer} timeout The default timeout in seconds for key chord input. Must be greater than 0.
     *  @param args* Additional arguments to pass to the Map constructor.
    **/
    __New(timeout?, args*)
    {
        this._orderedList := []
        
        if IsSet(timeout)
        {
            if (Mod(args.Length, 2) != 0)
                throw Error("Invalid number of arguments to KeyChord constructor")

            if !(timeout is Integer)
                throw ValueError("Argument must be an Integer", -1,"timeout: <" Type(timeout) ">")
            else if (timeout <= 0)
                throw ValueError("Argument must be greater than 0", -1,"timeout: " timeout)
            else
                this.Timeout := timeout
        }

        Loop args.Length // 2
            this[args[(A_index * 2) - 1]] := args[A_Index * 2]
    }

    ; Thank you to @Descolada on the AHK Discord for __Item and __Enum. I was looking for a
    ; solution to this problem (an ordered map), and I stumbled across a post where he provided
    ; a solution to someone else who wanted the same thing.

    /**
     * Gets or Sets an Item in the Map.
     * @param name The key to get the value of.
     * @returns {Any} The value of the key.
     */
    __Item[name]
    {
        get => this.Get(name)

        set
        {
            if !this.Has(name)
                this._orderedList.Push(name)
            this.Set(name, value)
        }
    }

    /**
     * Defines how the KeyChord should be enumerated
     * @param num The number of variables passed
     * @returns {KeyChord#__Enum~single | KeyChord#__Enum~pair} 
     */
    __Enum(num)
    {
        i := 0, len := this._orderedList.Length

        single(&x)
        {
            if ++i > len
                return False
            x := this._orderedList[i]
            return True
        }

        pair(&x, &y)
        {
            if ++i > len
                return False
            x := this._orderedList[i]
            y := this.Get(x)
            return True
        }

        return num == 1 ? single : pair
    }

    /**
     *  Sets a key-action pair in the KeyChord
     *  @param key The key which the user will press to execute `action`
     *  @param action The action to execute when the user presses `key`
    **/
    Set(key, action)
    {
        if (action is KeyChord.Action)
            super.Set(key, action)
        else if ((action is Object) && action.HasOwnProp("Command")) ; Check if the object has a Command property
            super.Set(key, KeyChord.Action(
                    action.Command,
                    action.HasOwnProp("Condition")   ? action.Condition   : True,
                    action.HasOwnProp("Description") ? action.Description : "Description not set."
                ))
        else if (action is KeyChord) || ((action is String) || (action is Integer) || (action is Float) || (action is Number) || (action is Func) || (action is BoundFunc) || (action is Closure) || (action is Enumerator))
            super.Set(key, KeyChord.Action(action, True))
        else
            throw ValueError("Argument must be a KeyChord.Action or Object with a Command property.", -1, Type(action)) ; Throw an error if the action is not a KeyChord.Action
    }

    /**
     *  Execute the KeyChord. Collect user input and react accordingly. 
    **/
    Execute(parent_key?)
    {
        if !(IsSet(parent_key))
            parent_key := ""

        keyString := ""
        for key, value in this
        {
            if (A_Index > 1)
                keyString .= ", "
            keyString .= key
        }

        TimedToolTip("Press a key...`n" keyString, this.Timeout)
        input := GetUserInput(this.Timeout)
        TimedToolTip(input, 1)

        if (input == "")
        {
            if this.RemindKeys
                KeyChordMsgBox(this, parent_key)

            TimedToolTip("Error: No input received.")
            return False
        }
        else
        {
            unsidedInput := RegExReplace(input, "(<|>)*", "")
        }

        if (this.Has(input) || this.Has(unsidedInput))
        {
            this.Get(input).Execute(parent_key ", " input)
            return True
        }
        else
        {
            for key, action in this
            {
                if (MatchWildcard(key, input) || MatchWildcard(key, unsidedInput))
                {
                    action.Execute(parent_key ", " input)
                    return True
                }
            }
        }

        TimedToolTip(text, duration?) => ( ToolTip(text), SetTimer(() => ToolTip(), -(IsSet(duration) ? 1000 * duration : 3000)) )

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
            } ; Adds curly braces to the keys in the array above, so they match the correct syntax expected by EndKeys

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

            ; Look for * and ? wildcard characters
            if (InStr(pattern, "*") || InStr(pattern, "?"))
            {
                pattern := StrReplace(pattern, "*", ".*")
                pattern := StrReplace(pattern, "?", ".")
                return MatchModifiers(patternModifiers, inputModifiers) && RegExMatch(input, "^" . pattern . "$")
            }

            ; Look for range characters
            if (InStr(pattern, "-"))
            {
                parts := StrSplit(pattern, "-")
                if (parts.Length == 2)
                {
                    start := Ord(parts[1])
                    end := Ord(parts[2])
                    inputChar := Ord(input)
                    return MatchModifiers(patternModifiers, inputModifiers) && (inputChar >= start && inputChar <= end)
                }
            }

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

            return false
        }

        KeyChordMsgBox(keymap, parent_key?)
        {
            msg_box := Gui()
            msg_box.Opt("+ToolWindow +AlwaysOnTop -Resize")
            msg_box.Title := "KeyChord Mappings for: " A_ThisHotkey parent_key
            msg_box.SetFont("s11", "Lucida Console")
            msg_box.AddText("X8 Y8", A_ThisHotkey parent_key)

            ParseKeyChord(keymap, 1)

            ok_btn := msg_box.AddButton("Default w80 X8 Y+5", "&OK")
            ok_btn.OnEvent("Click", (*) => msg_box.Destroy())
            msg_box.Show()

            ParseKeyChord(keymap, level)
            {
                wVal := 0
                xVal := ((level * 40) + 10) ; Ensure correct indentation for Sub-KeyChords

                for key in keymap
                    if StrLen(key) > wVal
                        wVal := 9 * StrLen(key) ; Gets the longest Key string in the KeyChord, this way we can ensure even placement of all descriptions

                for key, action in keymap
                {
                    if action.Command is KeyChord
                        msg_box.AddText("W" wVal " X" xVal " Y+5 cRed", key) ; KeyChord keys are Red
                    else
                        msg_box.AddText("W" wVal " X" xVal " Y+5 cBlue", key) ; Action keys are Blue

                    if action.Description == "Description not set."
                        msg_box.AddText("YP X+2 c949494", ": " action.Description) ; Unset descriptions are gray
                    else
                        msg_box.AddText("YP X+2 cBlack", ": " action.Description) ; Set descriptions are black
                    
                    ; If the Action has a description and is a KeyChord, increase the level and recursively iterate through that as well.
                    if (action.HasOwnProp("Description") && action.Command is KeyChord)
                    {
                        ParseKeyChord(action.Command, ++level)
                        --level
                    }
                }
            }
        }
    }

    /**
     *  Represents an action that can be executed as part of a KeyChord.
     *  
     *  An Action encapsulates a command, an optional condition that must be met in order to
     *  execute the command, and a short description of what the key will do when pressed.
     *  
     *  @constructor `Action(command, condition := True)`
     *  @property {KeyChord|Action|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} Command The command to be executed when the Action is executed.
     *  @property {Boolean|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} [Condition=True] The condition that must be met in order to execute the command. Defaults to `True`.
     *  @method `Execute()`: `Void` Executes the command if the condition is met.
    **/
    class Action
    {
        ; The command to be executed when the Action is executed.
        Command := ""
        ; The condition that must evaluate to True in order to execute the command.
        Condition := True
        ; The description if the user has the "remind keys" option for a KeyChord toggled on.
        Description := ""

        /**
         *  Initializes a new instance of the `Action` class.
         *  
         *  @param {Any} command The command to be executed when the Action is executed.
         *  @param {Boolean|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} [Condition=True] The condition that must be met in order to execute the command.
         */
        __New(command, condition := True, description := "Description not set")
        {
            switch Type(command)
            {
                case "KeyChord", "String", "Integer", "Number", "Float", "Func", "BoundFunc", "Closure", "Enumerator":
                    this.Command := command
                default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                    throw ValueError("Command must be or evaluate to a KeyChord, String, Integer, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Command: " Type(this.Command))
            }

            switch Type(condition)
            {
                case "String", "Integer", "Number", "Float", "Func", "BoundFunc", "Closure", "Enumerator":
                    this.Condition := condition
                default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                    throw ValueError("Condition must be or evaluate to a String, Integer, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Condition: " Type(this.Condition))
            }

            if (IsSet(description) && Type(description) == "String")
                this.Description := description
            else if !(Type(description) == "String")
                throw ValueError("Description must be or evaluate to a String", -1, "Description: " Type(this.Description))

            return
        }

        /**
         *  Evaluates the Action's Condition and, if True, executes the Action's Command.
         * 
         *  @param timeout {Integer} The timeout value for the action.
        **/
        Execute(key)
        {
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
                }
            }

            ; Check if this.Condition evaluates to true, if so, execute this.Command in the proper manner for it's type
            if EvaluateCondition(this.Condition)
            {
                switch Type(this.Command)
                {
                    Case "KeyChord":
                        this.Command.Execute(key)
                        return
                    Case "String", "Integer", "Boolean", "Number", "Float":
                        Send(this.Command)
                        return
                    Case "Func", "BoundFunc", "Closure", "Enumerator":
                        this.Command.Call()
                        return
                    Default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                        throw ValueError("Command must be a KeyChord, String, Integer, Boolean, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Command: " Type(this.Command))
                }
            }
        }
    }
}