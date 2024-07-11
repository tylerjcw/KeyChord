# KeyChord Class for AutoHotkey v2

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Classes](#classes)
  - [1. KeyChord Class](#1-keychord-class)
    - [KeyChord Constructor](#keychord-constructor)
    - [KeyChord Properties](#keychord-properties)
    - [KeyChord Methods](#keychord-methods)
  - [2. KeyChord.Action Class](#2-keychordaction-class)
    - [KeyChord.Action Constructor](#keychordaction-constructor)
    - [KeyChord.Action Properties](#keychordaction-properties)
    - [KeyChord.Action Methods](#keychordaction-methods)
- [Instructions](#instructions)
  - [Adding key-command mappings](#adding-key-command-mappings)
  - [Executing a KeyChord](#executing-a-keychord)
  - [Advanced Declaration Syntax](#advanced-declaration-syntax)
- [Examples](#examples)
  - [1. Basic KeyChord usage](#1-basic-keychord-usage)
  - [2. Nested KeyChords](#2-nested-keychords)
  - [3. Using default constructor](#3-using-default-constructor)
  - [4. Using conditions with KeyChord.Action](#4-using-conditions-with-keychordaction)
  - [5. Using wildcards](#5-using-wildcards)
  - [6. Combining features with conditions and wildcard patterns](#6-combining-features-with-conditions-and-wildcard-patterns)
  - [7. Using Custom Functions with the KeyChord Class](#7-using-custom-functions-with-the-keychord-class)

## Introduction

KeyChord is a class for AutoHotkey v2 that allows you to create complex key chords (key sequences, key chains, whatever you want to call them). It enables you to bind multiple actions to a series of keystrokes, creating a flexible and customizable hotkey system. KeyChord extends the `Map` class, and as such all of it's methods and properties are available, and they can be enumerated.

## Features

- Create nested key chord sequences
- Support for various types of actions (strings, numbers, functions, and nested KeyChords, to name a few)
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

`class KeyChord extends`[`Map`](https://www.autohotkey.com/docs/v2/lib/Map.htm)

- #### KeyChord Constructor

  `KeyChord(timeout?, args*)`
  - `timeout` : The default timeout (in seconds) for user input, optional. Defaults to 3 seconds.
  - `args*` : List of Key - Command Mappings (same syntax as Map or Map.Call). If no `args*` are passed, the KeyChord will be empty.

- #### KeyChord Properties

  - Native:
    - `Timeout`: The timeout (in seconds) for user input, default is 3 seconds.
  - Inherited:
    - [`Count`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Count): Retrieves the number of key-value pairs present.
    - [`Capacity`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Capacity): Retrieves or sets the current capacity of a KeyChord.
    - [`CaseSense`](https://www.autohotkey.com/docs/v2/lib/Map.htm#CaseSense): Retrieves or sets a map's case sensitivity setting. (Reccomended not to touch this)
    - [`Default`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Default): Defines the default value returned when a key is not found.
    - [`__Item`](https://www.autohotkey.com/docs/v2/lib/Map.htm#__Item): Retrieves or sets the value of a key-value pair.

- #### KeyChord Methods

  - Native:
    - `Execute(timeout := this.defaultTimeout)`
      - Executes the KeyChord, waiting for user input
      - `timeout`: The timeout for user input in seconds
  - Inherited:
    - [`Call`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Call) (`static`): Creates a KeyChord and sets items.
    - [`Clear`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Clear): Removes all key-value pairs from a KeyChord.
    - [`Clone`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Clone): Returns a shallow copy of a KeyChord.
    - [`Delete`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Delete): Removes a key-value pair from a KeyChord.
    - [`Get`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Get): Returns the value associated with a key, or a default value.
    - [`Has`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Has): Returns true if the specified key has an associated value within a KeyChord.
    - [`Set`](https://www.autohotkey.com/docs/v2/lib/Map.htm#Set): Sets zero or more items.
    - [`__Enum`](https://www.autohotkey.com/docs/v2/lib/Map.htm#__Enum): Enumerates key-value pairs.

### 2. KeyChord.Action Class

- #### KeyChord.Action Constructor

  `KeyChord.Action(command, condition := True)`
  - `command`: The action to perform
  - `condition`: An optional condition that must evaluate to `True` for the action to execute

- #### KeyChord.Action Properties

  - `Command`: The action to perform
  - `Condition`: The condition for execution

- #### KeyChord.Action Methods

  `Execute()`
  - Evaluates the Condition and Executes the Command if the condition is true.

___

## Instructions

### Adding key-command mappings

1. Using the `Set` method:
    `chord.Set(key, action)`
    - `key` is the key combination to map (e.g., "a", "^a", "#a", etc.).
    - `action` can be a Boolean, String, Integer, Float, Number, Func, BoundFunc, Closure, Enumerator, KeyChord.Action, or a nested KeyChord instance.

### Executing a KeyChord

1. Using the `Execute` method:
    `chord.Execute()`
        - During the time that this function is executing (no pun intended), the User's Hotkeys will be Suspended to avoid any conflicts.

### Advanced Declaration Syntax

Because `KeyChord.Action` is just a fancy object that has the properties `Command` and `Condition`, we can pass an inline object declaration with those two properties to the class instead of declaring a new `KeyChord.Action` in our code. That part will be handled by the KeyChord class in this case. This leads to my favorite way to declare a KeyChord:

```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(3,
    "c", {
        Condition: () => WinActive("ahk_exe Code.exe"),
        Command:   () => Run("calc.exe") },
    "s", {
        Condition: SomeFunction.Bind(arg1, arg2, arg3),
        Command:   SomeOtherFunction.Bind() },
    "d", KeyChord(3,
        "d", {
            Condition: () => True,
            Command:   Send.Bind(FormatTime(A_Now, "MM/dd/yy")) },
        "t", {
            Condition: () => (A_Hour < 12),
            Command:   Send.Bind(FormatTime(A_Now, "hh:mm tt")) }),
    "o", {
        Condition: () => WinActive("ahk_exe wordpad.exe"),
        Command:   "Typing, in WordPad." },
)

^#k::myKeyChord.Execute()
```

Or, for a more spread-out declaration (same thing, just adjusted braces and assigned the KeyChord right to the hotkey):

```ahk
#Include "KeyChord.ahk"

^#k::KeyChord(3,   
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
    "d", KeyChord(, ;<= No, thats not a Typo, you can omit an argument for the timeout value and it will default to 3 seconds.
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
        ),
    "o",
        {
            Condition: () => WinActive("ahk_exe wordpad.exe"),
            Command:   "Typing, in WordPad.",
        },
).Execute()
```

You could assign the KeyChord directly to a hotkey, like we did in  the second example above, by calling `^#k::KeyChord.CreateFromMap(timeout, map).Execute()`. However, if you assign it directly to a hotkey, you won't be able to dynamically add and remove bindings to and from the KeyChord. So it's best to just assign the KeyChord instance to a variable, and then assign the variable to a hotkey, as in the first example above. When using the above declaration syntax be extra careful and make sure you have commas on the ends of all the lines you need them on. Forgetting one comma can lead to some weird errors.

___

## Examples

### 1. Basic KeyChord usage

```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(2)  ; Create a new KeyChord with a 2-second timeout

myKeyChord.Set("c", Run.Bind("calc.exe"))
myKeyChord.Set("n", Run.Bind("notepad.exe"))
myKeyChord.Set("w", "Hello, World!")

^!k::myKeyChord.Execute()  ; Ctrl+Alt+K triggers the KeyChord
```

In this example, pressing any of the following within 2 seconds after pressing Ctrl+Alt+k:

- Pressing 'c' will launch the calculator
- Pressing 'n' will launch Notepad
- Pressing 'w' will type "Hello, World!"

___

### 2. Nested KeyChords

```ahk
#Include "KeyChord.ahk"

mainChord := KeyChord(3) ; KeyChord with 3 second timeout
subChord := KeyChord(2)  ; KeyChord with 2 second timeout

subChord.Set("g", Run.Bind("https://www.google.com"))
subChord.Set("b", Run.Bind("https://www.bing.com"))

mainChord.Set("c", Run.Bind("calc.exe"))
mainChord.Set("n", Run.Bind("notepad.exe"))
mainChord.Set("w", subChord)

^!m::mainChord.Execute()
```

In this example, within 3 seconds after pressing Ctrl+Alt+M:

- Pressing 'c' will launch the Calculator
- Pressing 'n' will launch Notepad
- Pressing 'w' will activate the subChord, then (within 2 seconds):
  - Pressing 'g' will open Google
  - Pressing 'b' will open Bing

Having multiple nested KeyChords will let you use the same button to trigger multiple different actions. For example, "Ctrl+I, then A, then P" might open MS Paint, but "Ctrl+I, then B, then P" might open Notepad.

___

### 3. Using default constructor

```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(3,
    "c", Run.Bind("calc.exe"),
    "n", Run.Bind("notepad.exe"),
    "w", KeyChord(2,
        "g", Run.Bind("https://www.google.com"),
        "b", Run.Bind("https://www.bing.com")
    )
)

^!k::myKeyChord.Execute()
```

This example creates the same structure as the [previous nested KeyChords example](#2-nested-keychords) but uses the constructor for a more concise setup.

___

### 4. Using conditions with KeyChord.Action

```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(2)

myKeyChord.Set("a", KeyChord.Action(Run.Bind("notepad.exe"), () => A_Hour < 12))
myKeyChord.Set("b", KeyChord.Action(Run.Bind("calc.exe"), () => A_Hour >= 12))

^!k::myKeyChord.Execute()
```

In this example, within 2 seconds after pressing Ctrl-Alt-k:

- Pressing 'a' will only launch Notepad if the current hour is before noon
- Pressing 'b' will only launch Calculator if the current hour is noon or later

___

### 5. Using wildcards

```ahk
#Include "KeyChord.ahk"

myKeyChord := KeyChord(2)

myKeyChord.Set("a-z", MsgBox.Bind("You pressed a letter!"))
myKeyChord.Set("0-9", () => MsgBox("You pressed a number!"))
myKeyChord.Set("F*" , MsgBox.Bind("You pressed F1-F24!"))

^!k::myKeyChord.Execute()
```

In this example, after pressing Ctrl+Alt+K:

- Pressing any letter from `a` to `z` will display a message box. This uses MsgBox.Bind() to bind the function call to the action.
- Pressing any number from `0` to `9` will display a message box. This uses a Fat arrow function to pass as the command.
- Pressing any function key (F1 through F24) will display a message box. This uses the asterisk wildcard to match against key names.

___

### 6. Combining features with conditions and wildcard patterns

```ahk
#Include "KeyChord.ahk"

mainChord := KeyChord()     ;
nestedChord := KeyChord()   ; KeyChords have a 3 second timeout value by default.
wildcardChord := KeyChord() ;

mainChord.Set("c", Run.Bind("calc"))
mainChord.Set("n", Run.Bind("notepad"))
mainChord.Set("1", nestedChord)
mainChord.Set("F*", wildcardChord)

nestedChord.Set("p", Run.Bind("mspaint"))
nestedChord.Set("w", KeyChord.Action(Run.Bind("wordpad"), () => A_Hour >= 9 && A_Hour < 17))

wildcardChord.Set("*a", Run.Bind("explorer.exe"))
wildcardChord.Set("b-d", KeyChord.Action(Run.Bind("https://www.google.com"), "A_ComputerName = 'MyComputer'"))

^#a::mainChord.Execute()
```

This example combines nested key chords, wildcard key-command mappings, regular key-command mappings, and conditions.

- The `mainChord` instance has mappings for "c" and "n" keys, a nested `nestedChord` instance mapped to the "1" key, and a `wildcardChord` instance mapped to the "F*" key (wildcard representing any key F1-F24).
- The `nestedChord` has a mapping for the "p" key to open Paint, and a mapping for the "w" key to open Wordpad, but only if the current hour is between 9 AM and 5 PM (inclusive).
-The `wildcardChord` has a wildcard mapping for "<+>+?" (LShift, RShift, and any other single character key) to open the File Explorer, and a range mapping for `b-f` (`b`, `c`, `d`, `e`, or `f`) to open Google, but only if the computer name is "MyComputer".

___

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
customChord.Set("c", KeyChord.Action(AddAndDisplay.Bind(number1, number2), IsNumberEven.Bind(number1, number2)))

; Bind the KeyChord instance to a hotkey
^#c::customChord.Execute()
```

In this example, when you press Ctrl+Win+c, then c again (within 3 seconds) `IsNumberEven(2, 6)` will be called, and if it returns true (in this example it will), `AddAndDisplay(2, 6)` will be called.
