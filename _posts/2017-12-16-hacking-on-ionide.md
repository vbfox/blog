---
layout: post
title: "Adding our first feature to Ionide"
tags: F#, Fable, Ionide, Javascript
---

*This post is part of the [F# Advent Calendar in English 2017](https://sergeytihon.com/2017/10/22/f-advent-calendar-in-english-2017/) organized by [Sergey Tihon](https://twitter.com/sergey_tihon)*

[Ionide](http://ionide.io/) is now one of the most used F# editing experience but it's pretty unique as it's based on an easily extensible editors: [Visual Studio Code](https://code.visualstudio.com/).

In the world of VSCode extensibility no arcane knowledge is required, the editor is open source with a well written code base (in [TypeScript](https://www.typescriptlang.org/)), the [plugin API](https://code.visualstudio.com/docs/extensionAPI/overview) is easy to get into and most plugins are open source too. While the Javascript (Or TypeScript) language might not be to the taste of everyone, we have [Fable](http://fable.io/) allowing us to continue to write F# and run in in the Javascript VM.

And Ionide is written in Fable, so we'll use Ionide and VSCode to edit Ionide itself.

Let's implement a very simple feature and then move to a bigger one! The simple feature will be to add a button in the editor when `.fsx` files are edited to call the `FSI: Send File` command, sending the full file to F# interactive. The more complex one will be to run the file in the terminal.

## Getting started

First you'll [need the prerequisites](https://github.com/ionide/ionide-vscode-fsharp/blob/master/CONTRIBUTING.md) (VScode, F#, dotnet, yarn, node, ...) then let's checkout a commit without the feature, run a first full build and start code :

```batch
git clone git@github.com:ionide/ionide-vscode-fsharp.git
cd ionide-vscode-fsharp
git checkout -b having_fun c0922fc
build build
code .
```

Once this first full build is setup well start our developer loop in VS Code:

* In the Integrated terminal (*View > Integrated Terminal* menu) we run `build watch` :
  <br/>![Build watch running](/assets/running-fsx/build-watch.png)
* In the debug view we select the `Launch Only` configuration:
  <br/>![Launch only being selected](/assets/running-fsx/debug-launch-only.png)
* Press `F5` to start a debug instance of VS Code.

Once started our loop is simple :

* Type new buggy code.
* Wait for the terminal to show that it rebuilt it successfully
* Move to the debug instance and press `F1` to run `Reload Window`
* Test
* Repeat

The loop is fast and while not as good as a browser with auto-reloading, pretty nice to use.

## A JSON-only feature

Our first target is to get something like that:

![Final result](/assets/running-fsx/send-to.png)

And we actually don't need any code to do it, as the command already exists the only thing we need to do is to to change the `release/package.json` file. And as added bonus it's not something that is build but instead used as-is by Code so we don't even need to wait for the watch build to test it, simply reloading the test instance window will allow us to see our changes.

While the file contains the same field as any `package.json` file, it's a section specific to Code that interest us : `contributes`. It contains all of the different things that the Ionide extensions declare that it's able to provide and it's [well documented on VS Code website](https://code.visualstudio.com/docs/extensionAPI/extension-points).

The command we want to run is shown as `FSI: Send File` in the command palette but to run it we'll need it's ID and that can be found in the `commands` section.

```json
{
  "contributes": {
    "commands": [
      {
        "command": "fsi.SendFile",
        "title": "FSI: Send File"
      }
    ]
  }
}
```

We currently want to show it in the editor title menu bar that is documented as being the `editor/title` section inside `menu`, so let's add it:

```json
{
  "contributes": {
    "menu": {
        "editor/title": [
          {
            "command": "fsi.SendFile",
            "when": "editorLangId == 'fsharp' && resourceExtname == '.fsx'",
            "group": "navigation"
          }
        ],
    }
  }
}
```

A few notes here:

* `command` is the command we wants to run, that we found just before
* `when` is the condition for it to appear, we want to be sure that the file is marked as F# (The language ID is auto detected but the user can also change it manually via the selector on the bottom right) and that it's a script (Sending `.fs` files is possible but we don't want to suggest it so prominently in the UI)
* `group` is used to group related commands but `navigation` is special as it tell code to make the item visible directly as an icon instead of being a line in the `...` menu (the default)

*Note: `resourceExtname` is a feature that was [added to VS Code](https://github.com/Microsoft/vscode/pull/34889) by Krzysztof Cieślak, the author of Ionide specifically for this change!*

We reload the window and...

![No icon](/assets/running-fsx/no-icon.png)

We forgot the icon 😢

Turns out that the icon is declared along with the command (And show everywhere the command is shown) instead of being part of the menu, so we'll get back to the command definition and add the icon

```json
{
  "contributes": {
    "commands": [
      {
        "command": "fsi.SendFile",
        "title": "FSI: Send File",
        "icon":
        {
          "light": "./images/send-light.svg",
          "dark": "./images/send-dark.svg"
        }
      }
    ]
  }
}
```

The images need to be placed in the `release/image` folder and to start copying existing ones is good enough. There are 2 images to allow for small variations between light and dark themes, but `icon` can also be the path to a single image if the distinction isn't needed.

And finally our feature is here, we can test it and verify that it works as expected, job done 🙌.

![Final result](/assets/running-fsx/send-to.png)

## Adding our own command

Now let's add another small feature: Running FSX scripts in the terminal

![Menu with run and send](/assets/running-fsx/run-icon.png)

To do that well go back to `package.json` and add our new command:

```json
{
  "contributes": {
    "commands": [
      {
        "command": "fsharp.scriptrunner.run",
        "title": "F#: Run script",
        "icon":
        {
          "light": "./images/run-light.svg",
          "dark": "./images/run-dark.svg"
        }
      }
    ],
    "menus": {
      "commandPalette": [
        {
          "command": "fsharp.scriptrunner.run",
          "when": "editorLangId == 'fsharp' && resourceExtname == '.fsx'"
        }
      ],
       "editor/title": [
        {
          "command": "fsharp.scriptrunner.run",
          "when": "editorLangId == 'fsharp' && resourceExtname == '.fsx'",
          "group": "navigation"
          }
        ]
      ]
    }
  }
}
```

We'll also need to add a new file to host our code in `src/Components/ScriptRunner.fs` and add it to the `.fsproj` file. (After this step the `watch` script might need to be restarted manually to pickup the new file)

```fsharp
namespace Ionide.VSCode.FSharp

open System
open Fable.Core
open Fable.Import.vscode
open Fable.Import.Node

module ScriptRunner =
    let private runFile () =
        printfn "Hello world"

    let activate (context: ExtensionContext) =
        commands.registerCommand(
            "fsharp.scriptrunner.run",
            runFile |> unbox<Func<obj,obj>>) |> context.subscriptions.Add
```

Adding the call to activate in `fsharp.fsx` is the final touch and our new button will finally do something (Even if it's only writing "Hello world" to the Debug Console)

```fsharp
// ...
Forge.activate context
Fsi.activate context // <--- Line added here
ScriptRunner.activate context

{ ProjectLoadedEvent = Project.projectLoaded.event
  BuildProject = MSBuild.buildProjectPath "Build"
  GetProjectLauncher = Project.getLauncher
  DebugProject = debugProject }
```

### Finally, we write some code

Let's start with the most simple addition, creating a terminal with a fixed name that run `fsi.exe` with the current file as single parameter

```fsharp
let private runFile () =
    let scriptFile = window.activeTextEditor.document.fileName
    let terminal = window.createTerminal("script", Environment.fsi, [| scriptFile|])
    terminal.show ()
```

It works but show a big problem with our approach as it closes immediately the terminal, before we can even read the results of executing our script.

A solution to this problem is to run a shell (`cmd.exe` for windows) and use it's capabilities instead of directly starting F# Interactive.

Ideally we would use it's arguments that allow to run commands but windows program arguments function differently than unix platforms: They are a single string and programs are free to parse them as they want. As NodeJS started on unix it's API wants an array of parameters that are then encoded using the [MSVCRT rules](http://www.daviddeley.com/autohotkey/parameters/parameters.htm#WINARGV) but `cmd.exe` parameter `/C` has a very special handling that doesn't follow theses conventions and we can't use it.

But VSCode allow us to send simulated keystrokes to the terminal so we'll use this

```fsharp
let private runFile () =
    let scriptFile = window.activeTextEditor.document.fileName
    let terminal = window.createTerminal("script", "cmd.exe", [||])
    terminal.sendText(sprintf "\"%s\" \"%s\" && pause && exit" Environment.fsi scriptFile)
    terminal.show ()
```

![First try, working](/assets/running-fsx/run-first-try.png)

We now have a working minimal sample and can start to build from there:

* We need to change our directory to the one of the script (the default is the root of the workspace) before running it
* The fixed title become confusing pretty fast if we run multiple different scripts

For both we might be tempted to use `System.IO`, but that's not something that's currently translated:

```
ERROR in ./src/Components/ScriptRunner.fs
G:/Code/_ext/ionide-fs/src/Components/ScriptRunner.fs(24,24): (24,67) error FABLE:
    Cannot find replacement for System.IO.Path::GetDirectoryName
 @ ./src/fsharp.fs 45:0-71
 @ ./src/Ionide.FSharp.fsproj
```

The solution is to use the [NodeJS Path API](https://nodejs.org/api/path.html) directly, the whole NodeJS API is provided by Fable in the [Fable.Import.Node Nuget package](https://www.nuget.org/packages/Fable.Import.Node/) that Ionide already import

```fsharp
open Fable.Import.Node

let private runFile () =
    let scriptFile = window.activeTextEditor.document.fileName
    let scriptDir = Path.dirname(scriptFile)

    let title = Path.basename scriptFile
    let terminal = window.createTerminal(title, "cmd.exe", [| "/K" |])
    terminal.sendText(sprintf "cd \"%s\" && \"%s\" \"%s\" && pause && exit" scriptDir Environment.fsi scriptFile)
    terminal.show ()
```

Now let's cleanup, add unix support and we're ready to send a PR:

```fsharp
namespace Ionide.VSCode.FSharp

open System
open Fable.Import.vscode
open Fable.Import.Node

module ScriptRunner =
    let private runFile (context: ExtensionContext) () =
        let scriptFile = window.activeTextEditor.document.fileName
        let scriptDir = Path.dirname(scriptFile)

        let (shellCmd, shellArgs, textToSend) =
            match Os.``type``() with
            | "Windows_NT" ->
                ("cmd.exe",
                 [| "/Q"; "/K" |],
                 sprintf "cd \"%s\" && cls && \"%s\" \"%s\" && pause && exit" scriptDir Environment.fsi scriptFile)
            | _ ->
                ("sh",
                 [||],
                 sprintf "cd \"%s\" && clear && \"%s\" \"%s\" && echo \"Press enter to close script...\" && read && exit" scriptDir Environment.fsi scriptFile)

        let title = Path.basename scriptFile
        let terminal = window.createTerminal(title, shellCmd, shellArgs)
        terminal.sendText(textToSend)
        terminal.show ()

    let activate (context: ExtensionContext) =
        commands.registerCommand(
            "fsharp.scriptrunner.run",
            runFile |> unbox<Func<obj,obj>>) |> context.subscriptions.Add
```

### Conclusion

VS Code an Ionide are the perfect introduction for any programmer that wants to start customizing his tools so don't hesitate.

You're missing an icon ? Some command would make your life easier ? Fork, Build, Contribute !