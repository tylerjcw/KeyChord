/**
 *  KeyChord.ahk
 *  
 *  A class for writing key chords in AutoHotKey.
 *  Now combinations like "Ctrl+Win+d, x, u" are supported!
 *  
 *  @version 1.5
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
#Requires AutoHotKey v2.0

/**
 *  Represents an action that can be executed as part of a KeyChord.
 *  
 *  A KCAction encapsulates a key, a command, an optional condition that must be met in order to
 *  execute the command, and an optional short description of what the KCAction does.
 *  
 *  @constructor `Action(key, command, condition?, description?)`
 *  @property {String} Key The key that must be pressed in order to execute the command.
 *  @property {KeyChord|Action|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} Command The command to be executed when the Action is executed.
 *  @property {Boolean|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} [Condition=True] The condition that must be met in order to execute the command. Defaults to `True`.
 *  @property {String} [Description="Description not set."] The description of what the Action does. Defaults to "Description not set.".
 *  @method `Execute()`: `Void` Executes the command if the condition is met.
 *  @method `ToString()`: `String` Returns a string representation of the Action.
 *  @method `Equals(action)`: `Boolean` Returns `True` if the specified object is equal to this Action.
 *  @method `EqualsStaticObject(object)`: `Boolean` Returns `True` if the specified object is equivalent to a KCAction.
**/
class KCAction
{
    /**
     * Returns the key in a more readable format. Like "Ctrl+Win", instead of "^#"
     * @returns {String} The key in a readable format.
    **/
    ReadableKey
    {
        get
        {
            key := ""
            key := StrReplace(this.Key, "<", "L")
            key := StrReplace(this.Key, ">", "R")
            key := StrReplace(this.Key, "+", "Shift+")
            key := StrReplace(this.Key, "^", "Ctrl+")
            key := StrReplace(this.Key, "!", "Alt+")
            key := StrReplace(this.Key, "#", "Win+")
            return key
        }
    }

    /**
     * Creates a new KCAction instance.
     * @param {String} key The key associated with this action.
     * @param {KeyChord|Action|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} command The command to be executed when the Action is executed.
     * @param {Any} condition The condition to evaluate before executing.
     * @param {String} description A description of the action.
    **/
    __New(key, command, condition := True, description := "Description not set.")
    {
        if !(Type(key) == "String" and key != "")
            throw ValueError("Key must be a non-empty String", -1, "Key: " Type(key))

        this.Key := key

        switch Type(command)
        {
            case "KeyChord", "String", "Integer", "Number", "Float", "Func", "BoundFunc", "Closure", "Enumerator":
                this.Command := command
            default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                throw ValueError("Command must be or evaluate to a KeyChord, String, Integer, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Command: " Type(command))
        }

        switch Type(condition)
        {
            case "String", "Integer", "Number", "Float", "Func", "BoundFunc", "Closure", "Enumerator":
                this.Condition := condition
            default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                throw ValueError("Condition must be or evaluate to a String, Integer, Number, Float, KeyChord, Func, BoundFunc, Closure, or Enumerator", -1, "Condition: " Type(condition))
        }

        if (IsSet(description) and Type(description) == "String")
            this.Description := description
        else if !(Type(description) == "String")
            throw ValueError("Description must be or evaluate to a String", -1, "Description: " Type(description))
        return
    }

    /**
     * Checks if the action's condition is true.
     * @param {Any} value The value to check (defaults to the action's condition).
     * @returns {Boolean} True if the condition is true, False otherwise.
    **/
    IsTrue(value := this.Condition)
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
                return this.IsTrue(value.Call())
            default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                throw ValueError("Condition must be or evaluate to a Boolean, String, Integer, Float, Number, Func, BoundFunc, Closure, or Enumerator", -1, "Condition: " Type(value))
        }
    }

    /**
     * Executes the action if its condition is true.
     * @param {Number} timeout The timeout for execution.
     * @param {String} parent_key The parent key string.
    **/
    Execute(timeout, parent_key)
    {
        if this.IsTrue()
        {
            switch Type(this.Command)
            {
                Case "KeyChord":
                    KCManager.Execute(this.Command, timeout, parent_key)
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

    /**
     * Returns a string representation of the KCAction.
     * @returns {String} A string describing the KCAction.
    **/
    ToString(indent := "")
    {
        switch Type(this.Command)
        {
            case "String", "Integer", "Number", "Float":
                command := this.Command
            case "KeyChord", "Func", "BoundFunc", "Closure", "Enumerator":
                command := Type(this.Command)
            default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                command := Type(this.Command)
        }

        switch Type(this.Condition)
        {
            case "String", "Integer", "Number", "Float", "Boolean":
                condition := (this.Condition ? "True" : "False")
            case "Func", "BoundFunc", "Closure", "Enumerator":
                condition := (this.Condition.Call() ? "True" : "False")
            default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                condition := Type(this.Condition)
        }
        

        out_str := "`n" indent ";------------------------------;"
        out_str .= "`n" indent "Key := `"" this.ReadableKey "`""
        out_str .= "`n" indent "Command := `"" command "`""
        out_str .= "`n" indent "Condition := " condition
        out_str .= "`n" indent "Description := `"" this.Description "`""

        if (this.Command is KeyChord)
        {
            out_str .= this.Command.ToString(indent . "`t")
        }

        return out_str
    }

    /**
     * Compares this KCAction with another for equality.
     * @param {KCAction} other - The other KCAction to compare with.
     * @returns {Boolean} True if the actions are equal, False otherwise.
    **/
    Equals(action)
    {
        return this.Key == action.Key
            and this.Command == action.Command
            and this.Condition == action.Condition
            and this.Description == action.Description
    }

    /**
     * Checks if an object is equivalent to a KCAction.
     * @param {Object} obj - The object to check.
     * @returns {Boolean} True if the object is equivalent to a KCAction, False otherwise.
    **/
    static EqualsObject(obj)
    {
        if (obj is Object)
            if obj.HasOwnProp("Key") and obj.HasOwnProp("Command")
                return True
        
        return False
    }
}





/**
 *  KeyChord class
 *  This class provides a way to map keys to commands or nested key Chords.
 *  It allows for executing commands or nested key Chords based on user input.
 *  
 *  @constructor `KeyChord(timeout?)`
 *  @property {Boolean} [RemindKeys=True] Whether to remind the user of the keys in the KeyChord.
 *  @property {Integer} Length The number of actions in the KeyChord.
 *  @method `Execute()`: `Void` Execute the keychord.
**/
class KeyChord
{
    RemindKeys := True

    /**
     * Gets the number of actions in the KeyChord.
     * @returns {Integer} The number of actions.
    **/
    Length => this._keyList.Length

    /**
     *  Initializes a new instance of the KeyChord class
     *  @param {KCAction} args* (Optional) A list of KCAction objects to add to the KeyChord.
    **/
    __New(actions*)
    {
        this._keyList         := []
        this._commandList     := []
        this._conditionList   := []
        this._descriptionList := []

        for action in actions
           this.AddActions(action)
    }

    /**
     * Gets or Sets an Item in the KeyChord.
     * @param name The key to get the value of.
     * @returns {KCAction} The action associated with the key
    **/
    __Item[name]
    {
        get
        {
            if (name is String)
                name := this.FirstIndexOf(name)
            else if not (name is Integer)
                throw ValueError("Invalid key type. Must be String or Integer", -1, "name: " Type(name))

            return KCAction(this._keyList[name], this._commandList[name], this._conditionList[name], this._descriptionList[name])
        }

        set
        {
            if !this._keyList.Has(name)
            {
                this._keyList.Push(value.Key)
                this._commandList.Push(value.Command)
                this._conditionList.Push(value.Condition)
                this._descriptionList.Push(value.Description)
            }
        }
    }

    /**
     *  Gets an Enumerator for the KeyChord.
     *  @param {Integer} num The number of elements to return.
     *  @returns {Func} A closure that returns the requested number of elements.
    **/
    __Enum(num)
    {
        i := 0
        len := this._keyList.Length

        ; KCAction object
        one(&x)
        {
            if ++i > len
                return False
            x := KCAction(this._keyList[i], this._commandList[i], this._conditionList[i], this._descriptionList[i])
            return True
        }

        ; Index, Key
        two(&x?, &y?)
        {
            if ++i > len
                return False
            x := i
            y := this._keyList[i]
            return True
        }

        ; Index, Key, Command
        three(&x?, &y?, &z?)
        {
            if ++i > len
                return False
            x := i
            y := this._keyList[i]
            z := this._commandList[i]
            return True
        }

        ; Index, Key, Command, Condition
        four(&w?, &x?, &y?, &z?)
        {
            if ++i > len
                return False
            w := i
            x := this._keyList[i]
            y := this._commandList[i]
            z := this._conditionList[i]
            return True
        }

        ; Index, Key, Command, Condition, Description
        five(&v?, &w?, &x?, &y?, &z?)
        {
            if ++i > len
                return False

            v := i
            w := this._keyList[i]
            x := this._commandList[i]
            y := this._conditionList[i]
            z := this._descriptionList[i]
            return True
        }

        switch (num)
        {
            case 1 : return one
            case 2 : return two
            case 3 : return three
            case 4 : return four
            case 5 : return five
            default: return Error("Invalid number of elements requested")
        }
    }

    /**
     * Adds one or more KCAction objects to the KeyChord.
     * @param {KCAction[]} actions* - The KCAction objects to add.
    **/
    AddActions(actions*)
    {
        for action in actions
        {
            if (action is KCAction) or (KCAction.EqualsObject(action))
            {
                if !this._keyList.Has(action.Key)
                {
                    this._keyList.Push(action.Key)
                    this._commandList.Push(action.Command)

                    if action.HasOwnProp("Condition")
                        this._conditionList.Push(action.Condition)
                    else
                        this._conditionList.Push(True)

                    if action.HasOwnProp("Description")
                        this._descriptionList.Push(action.Description)
                    else
                        this._descriptionList.Push("Description not set.")
                }
                else
                    throw ValueError("Key already exists", -1, "key: " action.Key)
            }
            else
                throw ValueError("Argument is not, or is not convertible to, a KCAction", -1, "action: " Type(action))
        }
    }

    /**
     *  Sets a key-action pair in the KeyChord
     *  @param {String} key The key which the user will press to execute `action`
     *  @param {Any} action The action to execute when the user presses `key`
     *  @param {String} [description="Description not set."] A description of the action
     *  @param {String} [condition=True] A condition to evaluate before executing the action
    **/
    Set(key, action, condition := True, description := "Description not set.")
    {
        if !this._keyList.Has(key)
        {
            this._keyList.Push(key)
            this._commandList.Push(action)
            this._conditionList.Push(condition)
            this._descriptionList.Push(description)
        }
        else
        {
            index := this.FirstIndexOf(key)
            this._commandList[index] := action
            this._conditionList[index] := condition
            this._descriptionList[index] := description
        }
    }

    /**
     * Gets a `KCAction` from the KeyChord, given a key
     * @param {String} key The key to get the action for
     * @returns {KCAction}
    **/
    Get(key)
    {
        index := this.FirstIndexOf(key)
        if this.Has(key)
        {
            return KCAction(this._keyList[index],
                this._commandList[index],
                this._conditionList[index],
                this._descriptionList[index])
        }
        else
        {
            throw ValueError("Key not found", -1, "key: " key)
        }
    }

    /**
     * Checks if the KeyChord contains a key
     * @param {String} key The key to check for
     * @returns {Boolean}
    **/
    Has(key)
    {
        unsidedKey := RegExReplace(key, "(<|>)*", "")

        for ,k in this._keyList
            if KeyChord.MatchKey(k, key) or KeyChord.MatchKey(k, unsidedKey)
                return True

        return False
    }

    /**
     * Removes an action by key.
     * @param {String} key - The key of the action to remove.
    **/
    Remove(key)
    {
        if this.Has(key)
        {
            index := this.FirstIndexOf(key)
            this._keyList.RemoveAt(index)
            this._commandList.RemoveAt(index)
            this._conditionList.RemoveAt(index)
            this._descriptionList.RemoveAt(index)
        }
    }

    /**
     * Removes all actions from the KeyChord.
    **/
    Clear()
    {
        this._keyList.Clear()
        this._commandList.Clear()
        this._conditionList.Clear()
        this._descriptionList.Clear()
    }    

    /**
     * Merges this KeyChord with another KeyChord.
     * @param {KeyChord} otherKeyChord - The KeyChord to merge with.
     * @returns {KeyChord} A new KeyChord containing the merged actions.
    **/
    Merge(keychords*)
    {
        for keychord in keychords
            for action in keychord
                this.AddActions(action)
        return this
    }

    /**
     * Returns a new KeyChord with actions sorted by key.
     * @returns {KeyChord} A new KeyChord with sorted actions.
    **/
    SortByKey()
    {
        sortedKeyChord := KeyChord()
        sortedKeys := this._keyList.Clone()
        sortedKeys.Sort()
        for key in sortedKeys
            sortedKeyChord.AddActions(this.Get(key))
        return sortedKeyChord
    }

    /**
     * Validates all actions in the KeyChord.
     * @returns {Boolean} True if all actions are valid, False otherwise.
    **/
    ValidateAll()
    {   
        for action in this
        {
            if !(action is KCAction)
                return false
            if !action.Key or !action.Command
                return false
        }
        return true
    }

    /**
     * Creates a deep copy of the KeyChord.
     * @returns {KeyChord} A new KeyChord with copied actions.
    **/
    Clone()
    {
        newKeyChord := KeyChord()
        for action in this
        {
            newCommand := action.Command is KeyChord ? action.Command.Clone() : action.Command
            newAction := KCAction(action.Key, newCommand, action.Condition, action.Description)
            newKeyChord.AddActions(newAction)
        }
        return newKeyChord
    }

    /**
     * Finds indexes of actions that match a given comparison function.
     * @param {Function} comparisonFunc A function that takes an action and returns true if it matches the criteria.
     * @returns {Array} An array of indexes where matching actions are found.
    **/
    FindIndexes(comparisonFunc)
    {
        indexes := []
        for action in this
            if comparisonFunc(action)
                indexes.Push(A_Index)
    
        return indexes
    }
    
    /**
     * Finds the index of the first occurrence of a key.
     * @param {String} key The key to search for.
     * @returns {Integer} The index of the first occurrence of the key, or 0 if not found.
    **/
    FirstIndexOf(key) => this.FindIndexes((action) => action.Key == key)[1]
    
    /**
     * Finds the index of the last occurrence of a key.
     * @param {String} key The key to search for.
     * @returns {Integer} The index of the last occurrence of the key, or 0 if not found.
    **/
    LastIndexOf(key)  => this.FindIndexes((action) => action.Key == key)[-1]
    
    /**
     * Finds all indexes of a key.
     * @param {String} key The key to search for.
     * @returns {Array} An array of all indexes where the key is found.
    **/
    AllIndexesOf(key) => this.FindIndexes((action) => action.Key == key)

    /**
     * Transforms the KeyChord by applying a function to each action.
     * @param {Function} func - The function to apply to each action.
     * @param {Boolean} [filterMode=false] - If true, filters out actions for which func returns false.
     * @returns {KeyChord} A new KeyChord with transformed actions.
     * 
     * Mapping Example:
     * ```ahk2
     * ; Appends "!!" to the end of the description of every action in the KeyChord
     * newKeyChord = keyChord.Transform((action) => ( action.Description .= "!!", return action ))
     * 
     * ; Sets every action's condition to False
     * newKeyChord = keyChord.Transform((action) => ( action.Condition := False, return action ))
     * ```
     * Filtering example:
     * ```ahk2
     * ; Filters out actions with key "Esc"
     * filteredKeyChord = keyChord.Transform(action => action.Key != "Esc", true)
     * 
     * ; Returns only the actions whos conditions are True
     * filteredKeyChord = keyChord.Transform(action => action.IsTrue(), true)
     * 
     * ; Returns only the actions whos Commands are of the type "String"
     * filteredKeyChord = keyChord.Transform(action => (action.Command is "String"), true)
     * ```
    **/
    Transform(func, filterMode := false)
    {
        newKeyChord := KeyChord()
        for action in this
        {
            if (filterMode)
            {
                if (func(action))
                    newKeyChord.AddActions(action)
            } 
            else
            {
                newAction := func(action)

                if (newAction is KCAction)
                    newKeyChord.AddActions(newAction)
                else
                    throw ValueError("Transform function must return a KCAction object when not in filter mode")
            }
        }
        return newKeyChord
    }

    /**
     * Finds actions with true conditions for a given key.
     * @param {String} key The key to search for.
     * @returns {KeyChord} The matching actions.
    **/
    FindTrue(key) => this.Transform((action) => action.Key == key and action.IsTrue(), True)

    /**
     * Finds the first action with a matching key and true condition.
     * @param {String} key - The key to match.
     * @returns {KCAction|undefined} The first matching action, or undefined if none found.
    **/
    FirstTrue(key) => this.Transform((action) => action.Key == key and action.IsTrue(), True)[1]

    /**
     * Finds the last action with a matching key and true condition.
     * @param {String} key - The key to match.
     * @returns {KCAction|undefined} The last matching action, or undefined if none found.
    **/
    LastTrue(key) => this.Transform((action) => action.Key == key and action.IsTrue(), True)[-1]
    
    /**
     * Returns all commands of a specific type.
     * @param {String} type - The type of commands to return.
     * @returns {Array} An array of commands of the specified type.
     */
    GetCommandsByType(type) => this.Transform((action) => (action.Command is type), True)

    /**
     * Returns a string representation of the KeyChord, including nested KeyChords.
     * @param {String} [indent=""] The indentation string for formatting nested structures.
     * @returns {String} A formatted string representation of the KeyChord.
    **/
    ToString(indent := "")
    {
        out_str := ""

        for action in this
        {
            out_str .= action.ToString(indent)
        }

        return Trim(out_str)
    }
    
    /**
     * Matches a key pattern against an input.
     * @param {String} pattern The key pattern to match.
     * @param {String} input The input to match against.
     * @returns {Boolean} True if the input matches the pattern, False otherwise.
    **/
    static MatchKey(pattern, input)
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
        if (InStr(pattern, "*") or InStr(pattern, "?"))
        {
            pattern := StrReplace(pattern, "*", ".*")
            pattern := StrReplace(pattern, "?", ".")
            return MatchModifiers(patternModifiers, inputModifiers) and RegExMatch(input, "^" . pattern . "$")
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
                return MatchModifiers(patternModifiers, inputModifiers) and (inputChar >= start and inputChar <= end)
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

        return False
    }
}





/**
 * KCManager
 * Manages the execution and interaction of KeyChords.
**/
class KCManager
{
    /**
     * Displays a timed tooltip.
     * @param {String} text The text to display.
     * @param {Number} duration The duration to display the tooltip.
    **/
    static TimedToolTip(text, duration?) => ( ToolTip(text), SetTimer(() => ToolTip(), -(IsSet(duration) ? 1000 * duration : 3000)) )

    /**
     * Executes a KeyChord.
     * @param {KeyChord} keychord The KeyChord to execute.
     * @param {Number} [mode=1] The execution mode.
     * @param {Number} [timeout=3] The timeout for execution.
     * @param {String} [parent_key=A_ThisHotkey] The parent key string.
     * @returns {Boolean} True if execution was successful, False otherwise.
    **/
    static Execute(keychord, mode := 1, timeout := 3, parent_key := A_ThisHotkey)
    {
        Loop
        {
            keyString := ""
            for action in keychord
            {
                if (A_Index > 1)
                    keyString .= ", "
                keyString .= action.ReadableKey
            }

            this.TimedToolTip("Press a key...`n" keyString, timeout)
            input := this.GetUserInput(timeout)
            this.TimedToolTip(input, 1)

            if !input
            {
                if keychord.RemindKeys
                    this.Help(keychord, parent_key)

                this.TimedToolTip("Error: No input received.")
                return False
            }
            else
            {
                switch mode
                {
                    case 1, "first", "f":
                        keychord := keychord.FirstTrue(input)
                    case 2, "last", "l":
                        keychord := keychord.LastTrue(input)
                    case 3, "all", "a":
                        keychord := keychord.FindTrue(input)
                }

                if keychord is KCAction
                    return keychord.Execute(timeout, parent_key)
                else if keychord.Length > 0
                    for action in keychord
                        action ? action.Execute(timeout, parent_key ", " input) : this.TimedToolTip("Error: Key not found.")

                return (keychord.Length > 0)
            }
        }
    }

    /**
     * Gets user input for a KeyChord.
     * @param {Number} timeout The timeout for input.
     * @returns {String} The user's input.
    **/
    static GetUserInput(timeout := 0)
    {
        overlay := KCManager.BlockingOverlay.Create()

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

        endTime := A_TickCount + timeout * 1000

        Loop
        {
            if (key.EndReason != "")
                break

            if (A_TickCount > endTime)
            {
                key.Stop()
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

            mouseButtons := ["LButton"  , "RButton"  , "MButton"  ,
                             "XButton1" , "XButton2" , "WheelUp"  ,
                             "WheelDown", "WheelLeft", "WheelRight"]

            ; Check to see if any of the mouse buttons are pressed,
            ; if they are, return the modifiers + mouse buttons.
            for mouseButton in mouseButtons
            {
                if (GetKeyState(mouseButton, "P"))
                {
                    key.Stop()
                    KeyWait(mouseButton)
                    Sleep(50)
                    Suspend(False)
                    KCManager.BlockingOverlay.Destroy()
                    return modifiers . mouseButton
                }
            }

            Sleep 10
        }

        KCManager.BlockingOverlay.Destroy()
        Suspend(False) ; Resume the user's hotkeys

        ; If not a special key, return the input, plus modifiers
        input := modifiers . (key.Input ? key.Input : key.EndKey)
        unsidedKey := RegExReplace(input, "(<|>)*", "")

        return input
    }

    /**
     * Displays help for a KeyChord.
     * @param {KeyChord} keychord The KeyChord to display help for.
     * @param {String} parent_key The parent key string.
    **/
    static Help(keychord, parent_key := A_ThisHotkey)
    {
        msg_box := Gui()
        msg_box.Opt("+ToolWindow +AlwaysOnTop -Resize") ; Set the GUI options
        msg_box.Title := "KeyChord Mappings for: " this.ParseKey(parent_key)
        msg_box.SetFont("s11", "Lucida Console") ; Set the font and size for the GUI
        msg_box.AddText("X8 Y8", this.ParseKey(parent_key)) ; Show "parent" key string
        key_list := msg_box.AddListView("w800 r20", ["Key", "Description", "Condition", "Type"])
        key_list.Opt("+Grid +NoSortHdr +NoSort")

        ParseKeyChord(keychord, 1) ; Recursively parse the KeyChord and dynamically add the Text elements to the GUI

        key_list.ModifyCol(2, "AutoHdr")
        msg_box.Show("AutoSize Hide") ; "Show" the GUI but keep it hidden, so we can get it's width
        ok_btn := msg_box.AddButton("Default w80 X+-" 80 " Y+5", "&OK") ; Add the button aligned to the right edge of the GUI
        ok_btn.OnEvent("Click", (*) => msg_box.Destroy()) ; Destroy the GUI when the button is clicked
        msg_box.Show("AutoSize") ; Resize the GUI and unhide it.

        ParseKeyChord(keychord, level, parentPrefix := "")
        {
            StrRepeat(s, c)
            {
                result := ""
                Loop c
                    result .= s
                return result
            }

            for action in keychord
            {
                key_name := action.ReadableKey
                isLastItem := (A_Index == keychord.Length)
                    
                linePrefix := parentPrefix
                if (level > 1)
                {
                    linePrefix .= isLastItem ? "└───" : "├───"
                }

                switch Type(action.Condition)
                {
                    case "String":
                        condition := (action.Condition != "" ? "True" : "False")
                    case "Integer", "Float", "Number":
                        condition := (action.Condition != 0 ? "True" : "False")
                    case "Func", "BoundFunc", "Closure", "Enumerator":
                        condition := (action.Condition.Call() ? "True" : "False")
                }

                spacePrefix := StrRepeat(" ", StrLen(linePrefix))
                cmd_type := (Type(action.Command) == "KeyChord") ? "KeyChord" : "Action"
                key_list.AddActions(, linePrefix . key_name, spacePrefix action.Description, spacePrefix condition, spacePrefix cmd_type)
            
                if (cmd_type == "KeyChord")
                {
                    newParentPrefix := parentPrefix
                    if (level > 1)
                        newParentPrefix .= isLastItem ? "    " : "│   "
                    ParseKeyChord(action.Command, level + 1, newParentPrefix)
                }
            }

            key_list.ModifyCol()
        }
    }

    /**
     * Parses a key string into a more readable format.
     * @param {String} key - The key string to parse.
     * @returns {String} The parsed key string.
    **/
    static ParseKey(key)
    {
        for symbol, replacement in  Map("<", "L", ">", "R", "+", "Shift+", "^", "Ctrl+", "!", "Alt+", "#", "Win+")
            key := StrReplace(key, symbol, replacement)

        return key
    }

    /**
     * BlockingOverlay
     * Manages a blocking overlay GUI.
    **/
    class BlockingOverlay
    {
        static instance := ""
    
        /**
         * Creates a new BlockingOverlay instance.
        **/
        __New()
        {
            this.overlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
            this.overlay.BackColor := "FFFFFF"
            this.overlay.Opt("-E0x20")
            this.overlay.Show("X0 Y0 W" A_ScreenWidth " H" A_ScreenHeight)
            WinSetTransparent(1, this.overlay)
        }
    
        /**
         * Creates or returns the existing BlockingOverlay instance.
        **/
        static Create()
        {
            if (!(this.instance))
            {
                this.instance := this()
            }
        }
    
        /**
         * Destroys the BlockingOverlay instance.
        **/
        static Destroy()
        {
            if (this.instance)
            {
                this.instance.overlay.Destroy()
                this.instance := ""
            }
        }
    }
}