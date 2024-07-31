# KeyChord Class for AutoHotkey v2

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Classes](#classes)
  - [1. KeyChord Class](#1-keychord-class)
    - [KeyChord Constructor](#keychord-constructor)
    - [KeyChord Properties](#keychord-properties)
    - [KeyChord Methods](#keychord-methods)
  - [2. KCAction Class](#2-kcaction-class)
    - [KCAction Constructor](#kcaction-constructor)
    - [KCAction Properties](#kcaction-properties)
    - [KCAction Methods](#kcaction-methods)
  - [3. KCManager Class](#3-kcmanager-class)
    - [KCManager Methods](#kcmanager-methods)
    - [KCManager.BlockingOverlay Subclass](#kcmanagerblockingoverlay-subclass)

## Introduction

KeyChord is a class for AutoHotkey v2 that allows you to create complex key chords (key sequences, key chains, whatever you want to call them). It enables you to bind multiple actions to a series of keystrokes, creating a flexible and customizable hotkey system. KeyChord extends the `Map` class, and as such all of it's methods and properties are available, and they can be enumerated.

Thank you to [Descolada](https://github.com/Descolada). The __Enum method was really cleared up for me after reading a forum post they made.
Thank you to [Nikola](https://github.com/nperovic/MouseHook) for the MouseHook script that helped me understand DllCalls and aided in the creation of the KCInputHook class.


## Features

- Create nested key chord sequences
- Support for various types of actions (strings, numbers, functions, and nested KeyChords, to name a few)
- Customizable timeout for key input
- Mouse Button support (`Lbutton`, `RButton`, `XButton1`, etc...)
- Conditional actions. Only executed if the attached condition is true.
  - Conditions can be any valid expression that evaluates to true or false.
  - Conditions can not be set on hotkeys that fire a nested KeyChord. This is a known limitation, and I may fix this in the future.
- Wildcard key matching
  - `?` matches any single character producing key, like `c`, `a`, or `9`. (no `Numpad4`, `PgUp`, `Delete`, etc...)
  - `*` can be used to match key names and represent multiple valid candidates.
    - `F*` would match any key `F1` to `F24`.
    - `F1*` would match any key `F1`, and `F10-F19`
    - `Num*` would match any key that starts with Num (`Numpad1`, `NumLock`, `NumpadEnd`, etc...)
    - `*PgUp` would match `PgUp` or `NumpadPgUp`
  - `a-b` is the range operator. It matches any key in the ascii range `a` to `b` inclusive. `a-f`, `0-9`, etc...
    - This matches based on the numeric character code (Ord), so any ASCII range where `Ord(a) <= Ord(b)` is valid.
    - `:-@` would match any of the following characters: `:`, `;`, `<`, `=`, `>`, `?`, `@` (ASCII Range 58-64).
    - [ASCII Character Table](https://www.ascii-code.com/ASCII)
- Useful Help window that can be attached to a hotkey.
- KeyChord class is fully enumerable, returning up to 5 values.
- `KeyChord.Transform(func)` function provides a powerful way to modify your KeyChords.

## Classes

### 1. KeyChord Class

`class KeyChord`

- #### KeyChord Constructor

  `KeyChord(actions*)`
  - `actions*`: A list of KCAction objects to add to the KeyChord, optional

  ```ahk
  exampleChord := KeyChord(
      KCAction("^a", Send.Bind("^a"), True, "Select all"),
      KCAction("^c", Send.Bind("^c"), True, "Copy")
  )

  exampleChord := KeyChord({
      Key: "^a",
      Command: () => Send("^a"),
      Condition: True,
      Description: "Select all" },
  {
      Key: "^c",
      Command: Send.Bind("^c"),
      Condition: True,
      Description: "Copy" }
  )
  ```

- #### KeyChord Properties

  - Native:
    - `RemindKeys`: Whether to remind the user of the keys in the KeyChord
    - `Length`: The number of actions in the KeyChord

- #### KeyChord Methods

  - Native:
    - `AddActions(actions*)`
      - Adds one or more KCAction objects to the KeyChord
      - `actions*`: The KCAction objects to add

      ```ahk
      exampleAction := KCAction("^m", Run.Bind("notepad"), () => (A_Hour > 12))

      exampleChord := KeyChord()
      exampleChord.Add(exampleAction)
      ```

    - `Set(key, action, condition := True, description := "Description not set.")`
      - Sets a key-action pair in the KeyChord
      - `key`: The key which the user will press to execute `action`
      - `action`: The action to execute when the user presses `key`
      - `condition`: A condition to evaluate before executing the action, optional
      - `description`: A description of the action, optional

      ```ahk
      exampleChord := KeyChord()
      exampleChord.Set("^s", "Save File", True, "Saves the current file")
      ```

    - `Get(key)`
      - Gets a `KCAction` from the KeyChord, given a key
      - `key`: The key to get the action for
      - Returns: `KCAction` object

      ```ahk
      action := exampleChord.Get("^s")
      MsgBox(action.Description)
      ```

    - `Has(key)`
      - Checks if the KeyChord contains a key
      - `key`: The key to check for
      - Returns: Boolean

      ```ahk
      if exampleChord.Has("^s")
          MsgBox("Save action exists")
      ```

    - `Remove(key)`
      - Removes an action by key
      - `key`: The key of the action to remove

      ```ahk
      exampleChord.Remove("^s")
      ```

    - `Clear()`
      - Removes all actions from the KeyChord

      ```ahk
      exampleChord.Clear()
      ```

    - `Merge(keychords*)`
      - Merges this KeyChord with other KeyChords
      - `keychords*`: The KeyChords to merge with
      - Returns: This KeyChord with merged actions

      ```ahk
      chord1 := KeyChord(KCAction("^a", "Select All"))
      chord2 := KeyChord(KCAction("^c", "Copy"))
      mergedChord := chord1.Merge(chord2)
      ```

    - `SortByKey()`
      - Returns a new KeyChord with actions sorted by key
      - Returns: New KeyChord with sorted actions

      ```ahk
      sortedChord := exampleChord.SortByKey()
      ```

    - `ValidateAll()`
      - Validates all actions in the KeyChord
      - Returns: Boolean indicating if all actions are valid

      ```ahk
      if exampleChord.ValidateAll()
          MsgBox("All actions are valid")
      ```

    - `Clone()`
      - Creates a deep copy of the KeyChord
      - Returns: New KeyChord with copied actions

      ```ahk
      clonedChord := exampleChord.Clone()
      ```

    - `FindIndexes(comparisonFunc)`
      - Finds indexes of actions that match a given comparison function
      - `comparisonFunc`: A function that takes an action and returns true if it matches the criteria
      - Returns: Array of indexes where matching actions are found

      ```ahk
      indexes := exampleChord.FindIndexes((action) => action.Key == "^s")
      ```

    - `FirstIndexOf(key)`
      - Finds the index of the first occurrence of a key
      - `key`: The key to search for
      - Returns: Integer index of the first occurrence of the key, or 0 if not found

      ```ahk
      index := exampleChord.FirstIndexOf("^s")
      ```

    - `LastIndexOf(key)`
      - Finds the index of the last occurrence of a key
      - `key`: The key to search for
      - Returns: Integer index of the last occurrence of the key, or 0 if not found

      ```ahk
      index := exampleChord.LastIndexOf("^s")
      ```

    - `AllIndexesOf(key)`
      - Finds all indexes of a key
      - `key`: The key to search for
      - Returns: Array of all indexes where the key is found

      ```ahk
      indexes := exampleChord.AllIndexesOf("^s")
      ```

    - `Transform(func, filterMode := false)`
      - Transforms the KeyChord by applying a function to each action
      - `func`: The function to apply to each action
      - `filterMode`: If true, filters out actions for which func returns false
      - Returns: New KeyChord with transformed actions

      ```ahk
      transformedChord := exampleChord.Transform((action) => (action.Description .= " (modified)"))
      ```

    - `FindTrue(key)`
      - Finds actions with true conditions for a given key
      - `key`: The key to search for
      - Returns: KeyChord with matching actions

      ```ahk
      trueActions := exampleChord.FindTrue("^s")
      ```

    - `FirstTrue(key)`
      - Finds the first action with a matching key and true condition
      - `key`: The key to match
      - Returns: KCAction or undefined if none found

      ```ahk
      firstTrueAction := exampleChord.FirstTrue("^s")
      ```

    - `LastTrue(key)`
      - Finds the last action with a matching key and true condition
      - `key`: The key to match
      - Returns: KCAction or undefined if none found

      ```ahk
      lastTrueAction := exampleChord.LastTrue("^s")
      ```

    - `GetCommandsByType(type)`
      - Returns all commands of a specific type
      - `type`: The type of commands to return
      - Returns: Array of commands of the specified type

      ```ahk
      stringCommands := exampleChord.GetCommandsByType("String")
      ```

    - `ToString(indent := "")`
      - Returns a string representation of the KeyChord, including nested KeyChords
      - `indent`: The indentation string for formatting nested structures
      - Returns: Formatted string representation of the KeyChord

      ```ahk
      chordString := exampleChord.ToString()
      MsgBox(chordString)
      ```

  - Static:
    - `MatchKey(pattern, input)`
      - Matches a key pattern against an input
      - `pattern`: The key pattern to match
      - `input`: The input to match against
      - Returns: Boolean indicating if the input matches the pattern

      ```ahk
      if KeyChord.MatchKey("^p-t", "^s")
          MsgBox("Key matched!")
      ```

### 2. KCAction Class

`class KCAction`

- #### KCAction Constructor

  `KCAction(key, command, condition?, description?)`

  - `key` : The key or key combination that triggers the action.
  - `command` : The command to execute when the action is triggered.
  - `condition` : (Optional) A condition that must be true for the action to be executed.
  - `description` : (Optional) A description of the action.

  ```ahk
  action := KCAction("a", () => MsgBox("A pressed"), () => true, "Press A to show message")
  ```

- #### KCAction Properties

  - `Key`: The key or key combination that triggers the action.
  - `Command`: The command to execute when the action is triggered.
  - `Condition`: The condition that must be true for the action to be executed.
  - `Description`: A description of the action.
  - `ReadableKey`: A human-readable representation of the key.
  
    ```ahk
    action := KCAction("^a", Run.Bind("notepad"))
    MsgBox(action.Key)  ; Displays "^a"
    MsgBox(action.ReadableKey)  ; Displays "Ctrl+a"
    ```

- #### KCAction Methods

  - Native:
    - `Execute(timeout?, parent_key?)`
      - Executes the action.
      - `timeout`: (Optional) The timeout for execution.
      - `parent_key`: (Optional) The parent key string.

      ```ahk
      action.Execute(5, "Ctrl+a")  ; Executes the action with a 5-second timeout and "Ctrl+a" as the parent key
      ```

    - `IsTrue()`
      - Checks if the condition for the action is true.
      - Returns: `Boolean` - True if the condition is met, False otherwise.

      ```ahk
      if (action.IsTrue())
          MsgBox("Action condition is true")
      ```

    - `ToString(indent?)`
      - Returns a string representation of the action.
      - `indent`: (Optional) The indentation string for formatting.
      - Returns: `String` - A formatted string representation of the action.

      ```ahk
      MsgBox(action.ToString("  "))  ; Displays the action details with 2-space indentation
      ```

    - `static EqualsObject(obj)`
      - Checks if an object is equivalent to a KCAction.
      - `obj`: The object to compare.
      - Returns: `Boolean` - True if the object is equivalent to a KCAction, False otherwise.

      ```ahk
      obj := {Key: "a", Command: () => MsgBox("A pressed"), Condition: () => true, Description: "Press A to show message"}
      if (KCAction.EqualsObject(obj))
          MsgBox("Object is equivalent to a KCAction")
      ```

### 3. KCManager Class

`class KCManager`

- #### KCManager Methods

  - Native:

    - `TimedToolTip(text, duration?)`
      - Displays a timed tooltip
      - `text`: The text to display
      - `duration`: The duration to display the tooltip in seconds, optional. Defaults to 3 seconds.

      ```ahk
      KCManager.TimedToolTip("Hello, World!", 5)
      ```

    - `Execute(keychord, mode := 1, timeout := 3, parent_key := A_ThisHotkey)`
      - Executes a KeyChord
      - `keychord`: The KeyChord to execute
      - `mode`: The execution mode (1: first, 2: last, 3: all), optional
      - `timeout`: The timeout for execution in seconds, optional
      - `parent_key`: The parent key string, optional
      - Returns: Boolean indicating if execution was successful

      ```ahk
      myKeyChord := KeyChord()
      myKeyChord.Set("a", () => MsgBox("A pressed"))
      result := KCManager.Execute(myKeyChord, 1, 5)
      ```

    - `GetUserInput(timeout := 0)`
      - Gets user input for a KeyChord
      - `timeout`: The timeout for input in seconds
      - Returns: String representing the user's input

      ```ahk
      userInput := KCManager.GetUserInput(5)
      MsgBox("User pressed: " . userInput)
      ```

    - `Help(keychord, parent_key := A_ThisHotkey)`
      - Displays help for a KeyChord
      - `keychord`: The KeyChord to display help for
      - `parent_key`: The parent key string, optional

      ```ahk
      myKeyChord := KeyChord()
      myKeyChord.Set("a", () => MsgBox("A pressed"), , "Press A for message")
      KCManager.Help(myKeyChord, "Ctrl+")
      ```

    - `ParseKey(key)`
      - Parses a key string into a more readable format
      - `key`: The key string to parse
      - Returns: String representing the parsed key string

      ```ahk
      parsedKey := KCManager.ParseKey("^!a")
      MsgBox("Parsed key: " . parsedKey)  ; Displays "Parsed key: Ctrl+Alt+a"
      ```

- #### KCManager.BlockingOverlay Subclass

  - Native:

    - `Create()`
      - Creates or returns the existing BlockingOverlay instance

      ```ahk
      KCManager.BlockingOverlay.Create()
      ```

    - `Destroy()`
      - Destroys the BlockingOverlay instance

      ```ahk
      KCManager.BlockingOverlay.Destroy()
      ```
