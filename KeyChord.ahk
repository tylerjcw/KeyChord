#Requires AutoHotKey v2.0

/**
 *  KeyChord.ahk
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
**/

/**
 *  Represents an action that can be executed as part of a KeyChord.
 *  ___
 *  A KCAction encapsulates a key, a command, an optional condition that must be met in order to
 *  execute the command, and an optional short description of what the KCAction does.
 *  ___
 *  @constructor `KCAction(key, command, condition?, description?)`
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
     * Returns the key in a more readable format. Like `Ctrl+Win`, instead of `^#`
     *
     * ```
     * action := KCAction("^#a", "Test command", True, "Test description")
     * MsgBox(action.ReadableKey) ; This will display "Ctrl+Win+a"
     * ```
     * ___
     * @returns {String} The key in a readable format.
    **/
    ReadableKey
    {
        get
        {
            replacements := Map("<", "L", ">", "R", "+", "Shift+", "^", "Ctrl+", "!", "Alt+", "#", "Win+")
            return RegExReplace(this.Key, "([<>+^!#])", "ReplaceModifier")
        }
    }

    Key := ""
    Command := () => ""
    Condition := True
    Description := ""

    /**
     * Creates a new KCAction instance.
     * 
     * ```
     * action := KCAction("a", "Test command", True, "Test description")
     * ```
     * ___
     * @param {String} key The key associated with this action.
     * @param {KeyChord|Action|String|Integer|Float|Number|Func|BoundFunc|Closure|Enumerator} command The command to be executed when `key` is pressed.
     * @param {Any} condition The condition to evaluate before executing. Must evaluate to true to execute the command.
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
     * Callout function for use in the `ReadableKey` property.
     * Added for compatibility with AHK versions >= 2.0.
     * ___
     * Replaces modifier symbols with their corresponding key names.
     * @param {string} match - The matched modifier symbol.
     * @param {string} _ - Unused parameter.
     * @param {string} __ - Unused parameter.
     * @returns {string} The key name corresponding to the modifier symbol.
    **/
    ReplaceModifier(m, _, __)
    {
        static replacements := Map("<", "Left", ">", "Right", "+", "Shift", "^", "Ctrl", "!", "Alt", "#", "Win")
        return replacements[m]
    }

    /**
     * Checks if the action's condition is true.
     * 
     * ```
     * action := KCAction("a", "Test command", True, "Test description")
     * 
     * if action.IsTrue()
     *   MsgBox("The condition is true") ; This will display
     * ```
     * ___
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
     * 
     * ```
     * action := KCAction("a", "Test command", True, "Test description") ; The condition is true
     * action.Execute() ; This will execute the command ("Test command" will be sent as text to the active window)
     * ```
     * ___
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
                    return KCManager.Execute(this.Command, , timeout, parent_key)
                Case "String", "Integer", "Boolean", "Number", "Float":
                    Send(this.Command)
                    return parent_key
                Case "Func", "BoundFunc", "Closure", "Enumerator":
                    this.Command.Call()
                    return parent_key
                Default: ; Array, Buffer, Error, File, Gui, InputHoot, Map, Menu, RegexMapInfo, VarRef, ComValue, any other custom class, or any other object
                    throw ValueError("Command must be a KeyChord, String, Integer, Boolean, Number, Float, Func, BoundFunc, Closure, or Enumerator", -1, "Command: " Type(this.Command))
            }
        }
    }

    /**
     * Returns a string representation of the KCAction.
     * 
     * ```
     * action := KCAction("a", "Test command", True, "Test description")
     * MsgBox(action.ToString())
     * ```
     * ___
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
     * Compares this `KCAction` with another for equality. All four properties must be _exactly_ the same on both `KCActions`.
     * 
     * ```
     * action1 := KCAction("a", "Test command", True, "Test description")
     * action2 := KCAction("a", "Test command", True, "Test description")
     * action3 := KCAction("a", "Test command", True, "I'm different!")
     * 
     * if (action1.Equals(action2))
     *   MsgBox("action1 is equal to action2") ; This will execute
     * 
     * if (action1.Equals(action3))
     *   MsgBox("action1 is equal to action3") ; This won't execute
     * 
     * ```
     * ___
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
     * The object in question must have a Key and Command property to be considered "Equal" to a KCAction.
     * 
     * ```
     * testObj = { Key: "a", Command: "Test command" }
     * 
     * if (KCAction.EqualsObject(testObj))
     *    MsgBox("testObj is equivalent to a KCAction")
     * ```
     * ___
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

;  Credit to nperovic on GitHub for the "MouseHook.ahk" script
;  that inspired and heavily influenced the KCInputHook class.
;  https://github.com/nperovic/MouseHook
/**
 *  An input hook that captures keyboard and mouse input.
 * 
 *  ```ahk2
 *  kcHook := KCInputHook()         ; Create an instance of KCInputHook
 *  loop
 *  {
 *      kcHook.Start()              ; Start the KCInputHook
 *      Result := kcHook.Wait(5000) ; Wait 5 seconds for user input
 *      kcHook.Stop()               ; Stop the KCInputHook

 *      MsgBox(result)              ; Display the result
 *  } until (Result == "Escape")    ; Exit the loop if the user presses the Escape key
 *  ```
 * ___
 *  @constructor `KCInputHook()`
 *  @property {String} Result The result of the input hook (includes modifiers).
 *  @property {String} Modifiers The modifiers that were pressed.
 *  @property {Boolean} IsCapturing Whether the input hook is currently capturing input.
**/
class KCInputHook
{
    _mouseLLHook := 0
    _mouseLLProc := 0
    _keyboardLLHook := 0
    _keyboardLLProc := 0
    Result := ""
    Modifiers := ""
    IsCapturing := False

    /**
     * Starts the KCInputHook capturing
     */
    Start()
    {
        Sleep(300) ; Sleep to give any keys that were pressed time to reset.
        this._mouseLLProc := CallbackCreate(this._mouseLLFunc.Bind(this), "F", 3)
        this._keyboardLLProc := CallbackCreate(this._keyboardLLFunc.Bind(this), "F", 3)
        this._mouseLLHook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", this._mouseLLProc, "Ptr", 0, "UInt", 0, "Ptr")
        this._keyboardLLHook := DllCall("SetWindowsHookEx", "Int", 13, "Ptr", this._keyboardLLProc, "Ptr", 0, "UInt", 0, "Ptr")
        this.IsCapturing := True
    }

    /**
     * Stops and resets the KCInputHook
     */
    Stop()
    {
        this.IsCapturing := False
        if (this._mouseLLHook)
            DllCall("UnhookWindowsHookEx", "Ptr", this._mouseLLHook)

        if (this._keyboardLLHook)
            DllCall("UnhookWindowsHookEx", "Ptr", this._keyboardLLHook)

        if (this._mouseLLProc)
            CallbackFree(this._mouseLLProc)

        if (this._keyboardLLProc)
            CallbackFree(this._keyboardLLProc)
        
        this.Clear()
    }

    /**
     * Makes sure all variables are reset
     */
    Clear()
    {
        this._mouseLLHook := 0
        this._mouseLLProc := 0
        this._keyboardLLHook := 0
        this._keyboardLLProc := 0
        this.Result := ""
        this.Modifiers := ""
        this.IsCapturing := False
    }

    /**
     * Low-Level Mouse Function
     * @param nCode 
     * @param wParam 
     * @param lParam 
     * @returns {Integer | Float | String} 
     */
    _mouseLLFunc(nCode, wParam, lParam)
    {
        if (nCode >= 0 && this.IsCapturing)
        {
            mouseData := NumGet(lParam + 8, "Int")
            switch wParam
            {
                case 0x0201: this.Result := "LButton"
                case 0x0204: this.Result := "RButton"
                case 0x0207: this.Result := "MButton"
                case 0x020B:
                    xButton := (mouseData >> 16) & 0xFFFF
                    this.Result := xButton == 1 ? "XButton1" : "XButton2"
                case 0x020A: this.Result := mouseData > 0 ? "WheelUp" : "WheelDown"
                case 0x020E: this.Result := mouseData > 0 ? "WheelRight" : "WheelLeft"
            }
            if (this.Result != "")
            {
                return 1  ; Block the event
            }
        }
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam, "Ptr")
    }

    /**
     * Low-Level Keyboard function
     * @param nCode  
     * @param wParam 
     * @param lParam 
     * @returns {Integer | Float | String} 
     */
    _keyboardLLFunc(nCode, wParam, lParam)
    {
        if (nCode >= 0 && this.IsCapturing)
        {
            vk := NumGet(lParam + 0, "UChar")
            sc := NumGet(lParam + 4, "UShort")
            key := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
            
            if (this.IsModifierKey(key))
            {
                if (wParam == 0x100 || wParam == 0x104)  ; WM_KEYDOWN or WM_SYSKEYDOWN
                {
                    this.UpdateModifiers(key, True)
                }
                else if (wParam == 0x101 || wParam == 0x105)  ; WM_KEYUP or WM_SYSKEYUP
                {
                    this.UpdateModifiers(key, False)
                }
            }
            else
            {
                if (wParam == 0x100 || wParam == 0x104)  ; WM_KEYDOWN or WM_SYSKEYDOWN
                {
                    this.Result := key
                }
                else if (wParam == 0x101 || wParam == 0x105)  ; WM_KEYUP or WM_SYSKEYUP
                {
                    this.Result := ""
                }
            }

            return 1  ; Block the event
        }
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam, "Ptr")
    }

    /**
     *  Checks whether a given key is a modifier key
     *  @param key The key to check
     *  @returns {Integer} 
     */
    IsModifierKey(key)
    {
        static modifierKeys := ["LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift", "LWin", "RWin"]
        for _key in modifierKeys
            if (key == _key)
                return True

        return False
    }


    /**
     *  Updates the active modifiers
     *  @param key The modifier to update
     *  @param isKeyDown Whether the key is being pressed or released
     */
    UpdateModifiers(key, isKeyDown)
    {
        modMap := Map(
            "LControl", "<^", "RControl", ">^",
            "LAlt", "<!",     "RAlt", ">!",
            "LShift", "<+",   "RShift", ">+",
            "LWin", "<#",     "RWin", ">#"
        )

        if (isKeyDown)
        {
            if (!InStr(this.Modifiers, modMap[key]))
                this.Modifiers .= modMap[key]
        }
        else
        {
            this.Modifiers := StrReplace(this.Modifiers, modMap[key], "")
        }
    }

    /**
     * Wait for input and return captured keys / mouse buttons
     * @param {Number} timeout How long the KCInputHook should wait for input in milliseconds. Default is -1 for indefinite.
     * @returns {String} 
     */
    Wait(timeout := -1) 
    {
        startTime := A_TickCount

        loop
        {
            if (timeout > 0 && A_TickCount - startTime > timeout)
            {
                this.IsCapturing := False
                return "Timeout"
            }

            if (this.Result != "")
            {
                finalResult := this.Modifiers . this.Result
                this.Result := ""
                this.IsCapturing := False
                return finalResult
            }

            Sleep(10)
        }
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
 *  @method `Execute()`: `Void` Execute the chord.
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
            else if (name < 1) or (name > this.Length)
                throw ValueError("Index out of range", -1, "name: " name)

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
     *  Credit goes to Descolada, who made a forum post that really cleared up the way "__Enum" works for me.
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
        for chord in keychords
            for action in chord
                this.AddActions(action)
        return this
    }

    /**
     * Returns a new KeyChord with actions sorted alphabetically by key.
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
     * 
     * ```
     * testChord := KeyChord( ... ) ; Build Your KeyChord
     * if !testChord.ValidateAll()
     *    MsgBox("Invalid KeyChord")
     * ```
     * 
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
     * Creates a deep copy of the KeyChord. Includes all Nested chords.
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
     * 
     * For example, the `FirstIndexOf()` method uses this function to find the first occurrence of a key:
     * ```
     * FirstIndexOf(key) => this.FindIndexes((action) => action.Key == key)[1]
     * ```
     * 
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
     * Finds all actions with true conditions for a given key.
     * 
     * @param {String} key The key to search for.
     * @returns {KeyChord} The matching actions.
    **/
    FindTrue(key) => this.Transform((action) => ((action.Key == key) or (action.Key == RegExReplace(key, "(<|>)*", ""))) and action.IsTrue(), True)

    /**
     * Finds the first action with a true condition for a given key.
     * 
     * @param {String} key - The key to match.
     * @returns {KCAction|undefined} The first matching action, or undefined if none found.
    **/
    FirstTrue(key)
    {
        result := this.FindTrue(key)
        if result.Length > 0
            return result[1]
        else
            KCManager.TimedToolTip("Error: Key not found.`nKey: " key, 3)
    }

    /**
     * Finds the last action with a true condition for a given key.
     * 
     * @param {String} key - The key to match.
     * @returns {KCAction|undefined} The last matching action, or undefined if none found.
    **/
    LastTrue(key)
    {
        result := this.FindTrue(key)
        if result.Length > 0
            return result[-1]
        else
            KCManager.TimedToolTip("Error: Key not found.`nKey: " key, 3)
    }
    
    /**
     * Returns all commands of a specific type.
     * 
     * ```
     * testChord := KeyChord( ... )
     * commands := testChord.GetCommandsByType("String")
     * for command in commands
     *     MsgBox(command)
     * ```
     * 
     * @param {String} type - The type of commands to return.
     * @returns {Array} An array of commands of the specified type.
     */
    GetCommandsByType(type) => this.Transform((action) => (action.Command is type), True)

    /**
     * Returns a string representation of the KeyChord, including nested KeyChords.
     * 
     * ```
     * chord := KeyChord(KCAction("a", "Test command", True, "Test description"), KCAction("b", "Test command", True, "Test description"))
     * MsgBox(chord.ToString())
     * ```
     * 
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
     * 
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
    static TimedToolTip(text, duration := 3) => ( ToolTip(text), SetTimer(() => ToolTip(), -(duration * 1000)) )

    /**
     * Executes a KeyChord.
     * 
     * ```
     * chord := KeyChord(KCAction("a", "Test command", True, "Test description"))
     * 
     * KCManager.Execute(chord, 1, 5)
     * ```
     * 
     * @param {KeyChord} chord The KeyChord to execute.
     * @param {Number} [mode=1] The execution mode. `1` = First True, `2` = Last True, `3` = All True.
     * @param {Number} [timeout=3] The timeout for execution.
     * @param {String} [parent_key=A_ThisHotkey] The parent key string. Used Internally, do not provide this argument.
     * @returns {Boolean} True if execution was successful, False otherwise.
    **/
    static Execute(chord, mode := 1, timeout := 3, parent_key := A_ThisHotkey)
    {
        Loop
        {
            keyString := ""
            if chord is KeyChord
            {
                for action in chord
                {
                 if (A_Index > 1)
                     keyString .= ", "
                 keyString .= action.ReadableKey
                }
            }

            this.TimedToolTip("Press a key...`n" keyString, timeout)
            input := this.GetUserInput(timeout)
            this.TimedToolTip(input)

            if not input or (input == "Timeout")
            {
                if chord.RemindKeys
                    this.Help(chord, parent_key)

                this.TimedToolTip("Error: No input received.")
                return "None Received"
            }
            else
            {
                switch mode
                {
                    case 1, "first", "f":
                        chord := chord.FirstTrue(input)
                    case 2, "last", "l":
                        chord := chord.LastTrue(input)
                    case 3, "all", "a":
                        chord := chord.FindTrue(input)
                }

                if chord is KCAction
                {
                    result := chord.Execute(timeout, parent_key ", " input)
                    return result
                }
                else if KCAction.EqualsObject(chord) and ((chord.Action is String) or (chord.Action is Number) or (chord.Action is Integer) or (chord.Action is Float))
                {
                    if IsSet(action)
                    {
                        result := action.Execute(timeout, parent_key ", " input)
                    }
                    else
                    {
                        this.TimedToolTip("Error: Key not found.`nInput: " input)
                    }

                    return parent_key ", " input
                }
                else if (chord is Array)
                {
                    if (chord.Length > 0)
                    {
                        for action in chord
                        {
                            if IsSet(action)
                                action.Execute(timeout, parent_key ", " input)
                            else
                            {
                                this.TimedToolTip("Error: Key not found.")
                            }
                        }

                        return parent_key ", " input
                    }
                }

                return "Key Not Found"
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
        if (timeout <= 0)
            throw ValueError("Timeout must be greater than 0", -1, Type(timeout) ": " timeout)

        kcHook := KCInputHook()

        try
        {
            kcHook.Start()
            input := kcHook.Wait(timeout * 1000)
        }
        catch as err
        {

        }
        finally
        {
            kcHook.Stop()
            kcHook := ""
        }

        return input
    }

    /**
     * Displays help for a KeyChord.
     * 
     * ```
     * testChord := KeyChord()
     * 
     * action1 := KCAction("n", () => Run("notepad"), True, "Notepad")
     * action2 := KCAction("h", () => KCManager.Help(testChord), True, "Displays Help")
     * 
     * testChord.AddActions(action1, action2)
     * ```
     * 
     * @param {KeyChord} chord The KeyChord to display help for.
     * @param {String} parent_key The parent key string.
    **/
    static Help(chord, parent_key := A_ThisHotkey)
    {
        msg_box := Gui()
        msg_box.Opt("+ToolWindow +AlwaysOnTop -Resize") ; Set the GUI options
        msg_box.Title := "KeyChord Mappings for: " this.ParseKey(parent_key)
        msg_box.SetFont("s11", "Lucida Console") ; Set the font and size for the GUI
        msg_box.AddText("X8 Y8", this.ParseKey(parent_key)) ; Show "parent" key string
        key_list := msg_box.AddListView("w800 r20", ["Key", "Description", "Condition", "Type"])
        key_list.Opt("+Grid +NoSortHdr +NoSort")

        ParseKeyChord(chord, 1) ; Recursively parse the KeyChord and dynamically add the Text elements to the GUI

        key_list.ModifyCol(2, "AutoHdr")
        msg_box.Show("AutoSize Hide") ; "Show" the GUI but keep it hidden, so we can get it's width
        ok_btn := msg_box.AddButton("Default w80 X+-" 80 " Y+5", "&OK") ; Add the button aligned to the right edge of the GUI
        ok_btn.OnEvent("Click", (*) => msg_box.Destroy()) ; Destroy the GUI when the button is clicked
        msg_box.Show("AutoSize") ; Resize the GUI and unhide it.

        ParseKeyChord(chord, level, parentPrefix := "")
        {
            StrRepeat(s, c)
            {
                result := ""
                Loop c
                    result .= s
                return result
            }

            for action in chord
            {
                key_name := action.ReadableKey
                isLastItem := (A_Index == chord.Length)
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
                key_list.Add(, linePrefix . key_name, spacePrefix action.Description, spacePrefix condition, spacePrefix cmd_type)
                
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
     * 
     * ```
     * key := "<^#>!a"
     * parsedKey := KCManager.ParseKey(key)
     * MsgBox(parsedKey) ; Output: "LCtrl+Win+RAlt+a"
     * ```
     * 
     * @param {String} key - The key string to parse.
     * @returns {String} The parsed key string.
    **/
    static ParseKey(key)
    {
        replacements := Map("<", "L", ">", "R", "+", "Shift+", "^", "Ctrl+", "!", "Alt+", "#", "Win+")
        return RegExReplace(key, "([<>+^!#])", (m) => replacements[m.1])
    }

    /**
     * BlockingOverlay
     * Manages a blocking overlay GUI. Used to keep mouse presses from reaching the active window while input is being collected.
     * 
     * Hopefully, this will be replaced with a more elegant solution in the future.
    **/
    class BlockingOverlay
    {
        static instance := ""
    
        /**
         * Creates a new `BlockingOverlay` instance.
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
         * Creates or returns the existing `BlockingOverlay` instance.
        **/
        static Create()
        {
            if (!(this.instance))
            {
                this.instance := this()
            }
        }
    
        /**
         * Destroys the `BlockingOverlay` instance.
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