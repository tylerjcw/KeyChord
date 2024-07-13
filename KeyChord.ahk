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
    RemindKeys := False ; If you want to change the default behavior of this option, this is where you do it
    Timeout := 3

    /**
     *  Initializes a new instance of the KeyChord class with the specified default timeout.
     *  
     *  @param {Integer} timeout The default timeout in seconds for key chord input. Must be greater than 0.
     *  @param args* Additional arguments to pass to the Map constructor.
    **/
    __New(timeout?, args*)
    {
        if IsSet(timeout)
        {
            if !(timeout is Integer)
                throw ValueError("Argument must be an Integer", -1,"timeout: <" Type(timeout) ">")
            else if (timeout <= 0)
                throw ValueError("Argument must be greater than 0", -1,"timeout: " timeout)
            else
                this.Timeout := timeout
        }

        for index, arg in args
        {
            if (Mod(index, 2) == 0)
                continue
    
            key := arg
            action := args[index + 1]
    
            this.Set(key, action)
        }
    }

    /**
     * 
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
                    action.HasOwnProp("Description") ? action.Description : ""
                ))
        else if (action is KeyChord) || ((action is String) || (action is Integer) || (action is Float) || (action is Number) || (action is Func) || (action is BoundFunc) || (action is Closure) || (action is Enumerator))
            super.Set(key, KeyChord.Action(action, True))
        else
            throw ValueError("Argument must be a KeyChord.Action or Object with a Command property.", -1, Type(action)) ; Throw an error if the action is not a KeyChord.Action
    }

    /**
     *  Execute the KeyChord. Collect user input and react accordingly. 
    **/
    Execute()
    {
        keyString := ""
        for key in this
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
            {
                MonoMsgBox(ParseDescriptions(this, 1, "`n" A_ThisHotkey "`n")) ;, "KeyChord Mappings", "O Iconi 4096")
            }

            TimedToolTip("Error: No input received.")
            return False
        }
        else
        {
            unsidedInput := RegExReplace(input, "(<|>)*", "")
        }

        if (this.Has(input) || this.Has(unsidedInput))
        {
            this.Get(input).Execute()
            return True
        }
        else
        {
            for key, action in this
            {
                if (MatchWildcard(key, input) || MatchWildcard(key, unsidedInput))
                {
                    action.Execute(this.Timeout)
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

        MatchWildcard(pattern, input)
        {
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
                return MatchModifiers(patternModifiers, inputModifiers) && RegExMatch(input, "^" . pattern . "$")
            }

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

            return false
        }

        ParseDescriptions(keychord, level, key_descriptions_string := "") ; ┬└─┐┴
        {
            for key, action in keychord
            {
                if (action.HasOwnProp("Description"))
                {
                    description := action.Description

                    if (Type(action.Command) == "KeyChord")
                    {
                        if IsSet(description)
                            key_descriptions_string .= RepStr("   ", level) . key "  -  " description "`n"
                        else
                            key_descriptions_string .= RepStr("   ", level) . key "  -  Description Not Set`n"

                        key_descriptions_string := ParseDescriptions(action.Command, level + 1, key_descriptions_string)
                    }
                    else
                    {
                        if IsSet(description)
                            key_descriptions_string .= RepStr("   ", level) . key "  -  " description "`n"
                        else
                            key_descriptions_string .= RepStr("   ", level) . key "  -  Description Not Set`n"
                    }
                }
            }

            RepStr(str, count)
            {
                result := ""
                Loop(count)
                    result .= str
                return result
            }

            return key_descriptions_string
        }

        MonoMsgBox(message)
        {
            msg_box := Gui()
            msg_box.Title := "KeyChord Mappings"
            msg_box.SetFont("s11", "Lucida Console")
            msg_text := msg_box.AddText(, message)
            ok_btn := msg_box.AddButton("Default w80 X+-80 Y+0", "&OK")
            ok_btn.OnEvent("Click", Destroy)
            msg_box.Show()
            
            Destroy(*)
            {
                msg_box.Destroy()
            }
        }
    }

    /**
     *  Represents an action that can be executed as part of a KeyChord.
     *  
     *  An Action encapsulates a command and an optional condition that must be met in order to execute the command.
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
        __New(command, condition, description:= "Description not set")
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
        Execute()
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
                        this.Command.Execute()
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