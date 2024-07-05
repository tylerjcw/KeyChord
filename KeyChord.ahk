/**
 *  KeyChord.ahk
 *  
 *  A class for writing key chords in AutoHotKey.
 *  Now combinations like "Ctrl+Win+d, x, u" are supported!
 *  
 *  @version 1.3
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
 *  @property {Map} commands Map of keys to commands.
 *  @property {Map} nestedChords Map of keys to nested KeyChord instances.
 *  @property {Integer} defaultTimeout The default timeout (in seconds) for user input.
 *  @method `Add(key)`: `Void` Adds a new command or key chord.
 *  @method `Delete(key)`: `Void` Deletes a command or key chord.
 *  @method `Clear()`: `Void` Clears all keys, commands, and nested KeyChords.
 *  @method `Execute(timeout)`: `Void` Execute the keychord.
**/
class KeyChord
{
    __New(defaultTimeout := 3)
    {
        ; Map of keys to nested KeyChord instances
        this.nestedChords := Map()

        ; Map of keys to commands
        this.commands := Map()
        
        ; Check to make sure timeout is valid
        if !(defaultTimeout <= 0)
        {
            this.defaultTimeout := defaultTimeout
        }
        else
        {
            MsgBox("Invalid timeout value: " defaultTimeout "`nTimeout must be greater than 0.", "Error")
        }
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
     *          RunOrActivate("Calculator", "calc")
     *  }
     *  ```
     *  
     *  @param {Integer} timeout The timeout in seconds.
     *  @param {Integer} length The length of the input in characters.
     *  @param {Integer} caseSensitive Whether or not the input should be case-sensitive.
     *  
     *  @return {String} The user's input key strokes.
    **/
    GetUserInput(timeout := 0, length := 1, caseSensitive := 0)
    {
        key := InputHook("L" length " T" timeout)

        key.Start()

        if !key.Wait()
        {
            MsgBox("Input timed out or failed.`nTimeout: " timeout "`nLength: " length, "Error")
            Return ""
        }
        return caseSensitive ? key.Input : StrLower(key.Input)
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
        this.keyChord := KeyChord(timeout)

        for key, action in bindingsMap
        {
            this.keyChord.Add(key, action)
        }

        return this.keyChord
    }

    /**
     *  Add a key-command mapping or a nested key Chord.
     *  @param {String} key The key to map
     *  @param {String|Integer|Float|BoundFunc|KeyChord} command - The command or nested key Chord to map
     *  @returns {Void}
    **/
    Add(key, command)
    {
        if IsObject(command) && (Type(command) == "KeyChord")
        {
            this.nestedChords.Set(key, command)
        }
        else
        {
            this.commands.Set(key, command)
        }
    }

    /**
     *  Remove a key-command mapping or a nested key Chord.
     *  @param {String} key The key to remove
     *  @returns {Void}
    **/
    Remove(key)
    {
        if this.commands.Has(key)
        {
            this.commands.Delete(key)
        }
        else if this.nestedChords.Has(key)
        {
            this.nestedChords.Delete(key)
        }
        else
        {
            MsgBox("Key not found: " key "`n`nPlease make sure the key is mapped correctly.`n`nExample:`nexampleKeyChord.Add(`"" key "`", Run.Bind(`"notepad`"))", "Error")
        }
    }

    /**
     *  Update a key-command mapping or a nested key Chord.
     *  @param {String} key The key to update.
     *  @param {String|Integer|Float|BoundFunc|KeyChord} newCommand - The new command or nested key Chord.
     *  @returns {Void}
    **/
    Update(key, newCommand)
    {
        if this.commands.Has(key)
        {
            this.commands.Set(key, newCommand)
        }
        else if this.nestedChords.Has(key)
        {
            this.nestedChords.Set(key, newCommand)
        }
        else
        {
            MsgBox("Key not found: " key "`n`nPlease make sure the key is mapped correctly.`n`nExample:`nexampleKeyChord.Add(`"" key "`", Run.Bind(`"notepad`"))", "Error")
        }
    }

    /**
     *  Clear all key-command mappings and nested key Chords.
     *  @returns {Void}
    **/
    Clear()
    {
        this.commands.Clear()
        this.nestedChords.Clear()
    }

    /**
     *  Execute the command or nested key Chord mapped to the user input.
     *  @param {Integer} timeout The timeout (in seconds) for user input.
     *  @returns {Void}
    **/
    Execute(timeout := this.defaultTimeout)
    {
        this.key := this.GetUserInput(timeout)

        if (this.key == "")
        {
            MsgBox("No input received.", "Error")
        }
        else if this.commands.Has(this.key)
        {
            this.command := this.commands.Get(this.key)
            this.ExecuteCommand(this.command, timeout)
        }
        else if this.nestedChords.Has(this.key)
        {
            this.nestedChord := this.nestedChords.Get(this.key)
            this.nestedChord.Execute(timeout)
        }
        else
        {
            MsgBox("Key not found: " this.key "`n`nPlease make sure the key is mapped correctly.`n`nExample:`nexampleKeyChord.Add(`"" this.key "`", Run.Bind(`"notepad`"))", "Error")
        }

        return
    }

    /**
     *  Execute the given command based on its type.
     *  @param {BoundFunc|Boolean|Integer|String|Float|KeyChord} command The "command" to execute
     *  @param {Integer} timeout The timeout (in seconds) for user input
     *  @returns {Void}
    **/
    ExecuteCommand(command, timeout)
    {
        cmdType := Type(command)

        Switch cmdType
        {
            Case "String", "Integer", "Boolean":
                Send(command)
                return
            Case "Float":
                Send(this.RoundToDecimalPlaces(command))
                return
            Case "KeyChord":
                command.Execute(timeout)
                return
            Case "BoundFunc":
                command.Call()
                return
            Default:
                MsgBox("Invalid Key Chord type: " cmdType, "Error")
                return
        }
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
}