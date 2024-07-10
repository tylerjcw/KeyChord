# KeyChord Class for AutoHotkey v2

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Classes](#classes)
  - [1. KeyChord Class](#1-keychord-class)
    - [Constructor](#constructor)
    - [Properties](#properties)
    - [Methods](#methods)
      - [a) Add(key, action)](#a-addkey-action)
      - [b) Remove(key)](#b-removekey)
      - [c) Update(key, newAction)](#c-updatekey-newaction)
      - [d) Clear()](#d-clear)
      - [e) Execute(timeout := this.defaultTimeout)](#e-executetimeout--thisdefaulttimeout)
      - [f) static CreateFromMap(timeout, bindingsMap)](#f-static-createfrommaptimeout-bindingsmap)
  - [2. KeyChord.Action Class](#2-keychordaction-class)
    - [Constructor](#constructor-1)
    - [Properties](#properties-1)
    - [Method](#method)
- [Instructions](#instructions)
    - [Creating a KeyChord instance](#creating-a-keychord-instance)
    - [Adding key-command mappings](#adding-key-command-mappings)
    - [Executing a KeyChord](#executing-a-keychord)
    - [Advanced Declaration Syntax](#advanced-declaration-syntax)
- [Usage Examples](#usage-examples)
  - [1. Basic KeyChord usage](#1-basic-keychord-usage)
  - [2. Nested KeyChords](#2-nested-keychords)
  - [3. Using CreateFromMap](#3-using-createfrommap)
  - [4. Using conditions with KeyChord.Action](#4-using-conditions-with-keychordaction)
  - [5. Using wildcards](#5-using-wildcards)
  - [6. Combining features with conditions and wildcard patterns](#6-combining-features-with-conditions-and-wildcard-patterns)
  - [7. Using Custom Functions with the KeyChord Class](#7-using-custom-functions-with-the-keychord-class)

## Introduction

KeyChord is a class for AutoHotkey v2 that allows you to create complex key chords (key sequences, key chains, whatever you want to call them). It enables you to bind multiple actions to a series of keystrokes, creating a flexible and customizable hotkey system.

## Features

- Create nested key chord sequences
- Support for various types of actions (strings, numbers, functions, and nested KeyChords)
- Customizable timeout for key input
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

## Classes

### 1. KeyChord Class

- #### Constructor

    `KeyChord(defaultTimeout := 3)`
    - `defaultTimeout` : The default timeout (in seconds) for user input

- #### Properties

    - `chords` : Map of keys to actions
    - `nestedChords` : Map of keys to nested KeyChord instances
    - `wildcards` : Map of wildcard keys to actions
    - `defaultTimeout` : The default timeout for user input

- #### Methods

    - `Add(key, action)`

        - Adds a new key-action mapping to the KeyChord
        - `key`: The key or key combination to trigger the action
        - `action`: The action to perform (can be a value, function, or nested KeyChord)

    - `Remove(key)`

        - Removes a key-action mapping from the KeyChord
        - `key`: The key to remove

    - `Update(key, newAction)`

        - Updates an existing key-action mapping
        - `key`: The key to update
        - `newAction`: The new action to associate with the key

    - `Clear()`

        - Removes all key-action mappings from the KeyChord

    - `Execute(timeout := this.defaultTimeout)`

        - Executes the KeyChord, waiting for user input
        - `timeout`: The timeout for user input in seconds

    - `static CreateFromMap(timeout, bindingsMap)`

        - Creates a new KeyChord instance from a map of key-action bindings
        - `timeout`: The timeout for user input in seconds
        - `bindingsMap`: A map of key-action bindings

### 2. KeyChord.Action Class

- #### Constructor

    `KeyChord.Action(command, condition := True)`
    - `command`: The action to perform
    - `condition`: An optional condition that must be true for the action to execute

- #### Properties

    - `Command`: The action to perform
    - `Condition`: The condition for execution

- #### Method

    `Execute()`
    - Evaluates the Condition and Executes the Command if the condition is true.
___
## Instructions
### Creating a KeyChord instance:
1. Using the constructor:
    `chord := KeyChord(timeout)`
    - `timeout` (optional) is the default timeout in seconds for key chord input. If not provided, it defaults to 3 seconds.

2. Using the static `CreateFromMap` method:
    `chord := KeyChord.CreateFromMap(timeout, bindingsMap)`
    - `timeout` is the timeout in seconds for key chord input.
    - `bindingsMap` is a Map of key-command bindings.

### Adding key-command mappings:
1. Using the `Add` method:
    `chord.Add(key, action)`
    - `key` is the key combination to map (e.g., "a", "^a", "#a", etc.).
    - `action` can be a boolean, string, integer, float, Func, BoundFunc, KeyChord.Action, or a nested KeyChord instance.

### Executing a KeyChord:
1. Using the `Execute` method:
    `chord.Execute(timeout)`
    - `timeout` (optional) is the timeout in seconds for user input. If not provided, the default timeout of 3 seconds is used.

### Advanced Declaration Syntax:
Because `KeyChord.Action` is just a fancy object that has the properties `Command` and `Condition`, we can pass an inline object declaration with those two properties to the class instead of declaring a new KeyChord.Action() in our code. That part will be handled by the KeyChord class in this case. This leads to my favorite way to declare a KeyChord:
```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord.CreateFromMap(3, Map(
    "c", {
        Condition: () => WinActive("ahk_exe Code.exe"),
        Command:   () => Run("calc.exe") },
    "s", {
        Condition: SomeFunction.Bind(arg1, arg2, arg3),
        Command:   SomeOtherFunction.Bind() },
    "d", KeyChord.CreateFromMap(3, Map(
        "d", {
            Condition: () => True,
            Command:   Send.Bind(FormatTime(A_Now, "MM/dd/yy")) },
        "t", {
            Condition: () => (A_Hour < 12),
            Command:   Send.Bind(FormatTime(A_Now, "hh:mm tt")) })),
    "o", {
        Condition: () => WinActive("ahk_exe wordpad.exe"),
        Command:   "Typing, in WordPad." },
))

^#k::myKeyChord.Execute()
```
Or, for a more spread-out declaration (same thing, just adjusted braces and assigned the KeyChord right to the hotkey):
```ahk
#Include "KeyChord.ahk"

^#k::KeyChord.CreateFromMap(3, Map(   
    "c",
        {
            Condition: () => WinActive("ahk_exe Code.exe"),
            Command:   () => Run("calc.exe"),
        },
    "s",
        {
            Condition: SomeFunction.Bind(arg1, arg2, arg3),
            Command:   SomeOtherFunction.Bind(),
        },
    "d", KeyChord.CreateFromMap(3, Map(
        "d",
            {
                Condition: () => True,
                Command:   Send.Bind(FormatTime(A_Now, "MM/dd/yy")),
            },
        "t",
            {
                Condition: () => (A_Hour < 12),
                Command:   Send.Bind(FormatTime(A_Now, "hh:mm tt")),
            },
        )),
    "o",
        {
            Condition: () => WinActive("ahk_exe wordpad.exe"),
            Command:   "Typing, in WordPad.",
        },
)).Execute()
```
You could assign the KeyChord directly to a hotkey, like we did in  the second example above, by calling `^#k::KeyChord.CreateFromMap(timeout, map).Execute()`. However, if you assign it directly to a hotkey, you won't be able to dynamically add and remove bindings to and from the KeyChord. So it's best to just assign the KeyChord instance to a variable, and then assign the variable to a hotkey, as in the first example above. When using the above declaration syntax be extra careful and make sure you have commas on the ends of all the lines you need them on. Forgetting one comma can lead to some weird errors.

___
## Examples
### 1. Basic KeyChord usage

```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(2)  ; Create a new KeyChord with a 2-second timeout

myKeyChord.Add("c", Run.Bind("calc.exe"))
myKeyChord.Add("n", Run.Bind("notepad.exe"))
myKeyChord.Add("w", "Hello, World!")

^!k::myKeyChord.Execute()  ; Ctrl+Alt+K triggers the KeyChord
```
In this example, pressing any of the following within 2 seconds after pressing Ctrl+Alt+k:

- Pressing 'c' will launch the calculator
- Pressing 'n' will launch Notepad
- Pressing 'w' will type "Hello, World!"

***
### 2. Nested KeyChords
```ahk
#Include "KeyChord.ahk"

mainChord := KeyChord(3) ; KeyChord with 3 second timeout
subChord := KeyChord(2)  ; KeyChord with 2 second timeout

subChord.Add("g", Run.Bind("https://www.google.com"))
subChord.Add("b", Run.Bind("https://www.bing.com"))

mainChord.Add("c", Run.Bind("calc.exe"))
mainChord.Add("n", Run.Bind("notepad.exe"))
mainChord.Add("w", subChord)

^!m::mainChord.Execute()
```
In this example, within 3 seconds after pressing Ctrl+Alt+M:

- Pressing 'c' will launch the Calculator
- Pressing 'n' will launch Notepad
- Pressing 'w' will activate the subChord, then (within 2 seconds):
    - Pressing 'g' will open Google
    - Pressing 'b' will open Bing

Having multiple nested KeyChords will let you use the same button to trigger multiple different actions. For eaxampl "Ctrl+I, then A, then P" might open MS Paint, but "Ctrl+I, then B, then P" might open Notepad.

***
### 3. Using CreateFromMap
```ahk
#Include "KeyChord.ahk"

keyBindings := Map(
    "c", Run.Bind("calc.exe"),
    "n", Run.Bind("notepad.exe"),
    "w", KeyChord.CreateFromMap(2, Map(
        "g", Run.Bind("https://www.google.com"),
        "b", Run.Bind("https://www.bing.com")
    ))
)

myKeyChord := KeyChord.CreateFromMap(3, keyBindings)

^!k::myKeyChord.Execute()
```
This example creates the same structure as the [previous nested KeyChords example](#2-nested-keychords) but uses the CreateFromMap method for a more concise setup. 

***
### 4. Using conditions with KeyChord.Action
```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(2)

myKeyChord.Add("a", KeyChord.Action(Run.Bind("notepad.exe"), () => A_Hour < 12))
myKeyChord.Add("b", KeyChord.Action(Run.Bind("calc.exe"), () => A_Hour >= 12))

^!k::myKeyChord.Execute()
```
In this example, within 2 seconds after pressing Ctrl-Alt-k:

- Pressing 'a' will only launch Notepad if the current hour is before noon
- Pressing 'b' will only launch Calculator if the current hour is noon or later

***
### 5. Using wildcards
```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(2)

myKeyChord.Add("a-z", MsgBox.Bind("You pressed a letter!"))
myKeyChord.Add("0-9", () => MsgBox("You pressed a number!"))
myKeyChord.Add("F*" , MsgBox.Bind("You pressed F1-F24!"))

^!k::myKeyChord.Execute()
```
In this example, after pressing Ctrl+Alt+K:

- Pressing any letter from `a` to `z` will display a message box. This uses MsgBox.Bind() to bind the function call to the action.
- Pressing any number from `0` to `9` will display a message box. This uses a Fat arrow function to pass as the command.
- Pressing any function key (F1 through F24) will display a message box. This uses the asterisk wildcard to match against key names.

***
### 6. Combining features with conditions and wildcard patterns
```ahk
#Include "KeyChord.ahk"

mainChord := KeyChord(3)
nestedChord := KeyChord(3)
wildcardChord := KeyChord(3)

mainChord.Add("c", Run.Bind("calc"))
mainChord.Add("n", Run.Bind("notepad"))
mainChord.Add("1", nestedChord)
mainChord.Add("F*", wildcardChord)

nestedChord.Add("p", Run.Bind("mspaint"))
nestedChord.Add("w", KeyChord.Action(Run.Bind("wordpad"), () => A_Hour >= 9 && A_Hour < 17))

wildcardChord.Add("*a", Run.Bind("explorer.exe"))
wildcardChord.Add("b-d", KeyChord.Action(Run.Bind("https://www.example.com"), "A_ComputerName = 'MyComputer'"))

^#a::mainChord.Execute()
```

This example combines nested key chords, wildcard key-command mappings, regular key-command mappings, and conditions.
- The `mainChord` instance has mappings for "c" and "n" keys, a nested `nestedChord` instance mapped to the "1" key, and a `wildcardChord` instance mapped to the "F*" key (wildcard representing any key F1-F24).
- The `nestedChord` has a mapping for the "p" key to open Paint, and a mapping for the "w" key to open Wordpad, but only if the current hour is between 9 AM and 5 PM (inclusive).
-The `wildcardChord` has a wildcard mapping for "<+>+?" (LShift, RShift, and any other single character key) to open the File Explorer, and a range mapping for `b-f` (`b`, `c`, `d`, `e`, or `f`) to open the "https://www.example.com" website, but only if the computer name is "MyComputer".

***
### 7. Using Custom Functions with the KeyChord Class

The most common way to use a custom function as a command with the KeyChord class is to create an Action object with the function bound to the `Command` or `Condition` property using the Bind method. Functions Bound to the `Condition` property must evaluate to a true / false value. Here's an example:
```ahk
#Include "KeyChord.ahk"

; Define a custom function
AddAndDisplay(param1, param2)
{
    result := param1 + param2
    MsgBox("Result of addition:`n" param1 "+" param2 "=" result)
}

IsNumberEven(param1, param2)
{
    if (param1 % 2) == 0
        return true
}

number1 := 2
number2 := 6

; Create a KeyChord instance
customChord := KeyChord()

; Add a key-command mapping using the custom function
customChord.Add("c", KeyChord.Action(AddAndDisplay.Bind(number1, number2), IsNumberEven.Bind(number1, number2)))

; Bind the KeyChord instance to a hotkey
^#c::customChord.Execute()
```
In this example, when you press Ctrl+Win+c, then c again (within 3 seconds) `IsNumberEven(2, 6)` will be called, and if it returns true (in this example it will), `AddAndDisplay(2, 6)` will be called.