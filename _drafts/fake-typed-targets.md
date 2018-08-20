---
layout: post
title: "Replacing FAKE target strings with types"
tags: F#, FAKE, Build, DevOps
---

Now on [NuGet](https://www.nuget.org/packages/BlackFox.Fake.BuildTask/)


```fsharp
#r "paket:
nuget BlackFox.Fake.BuildTask
nuget Fake.Core.Target //"
#load "./.fake/build.fsx/intellisense.fsx"

open BlackFox.Fake
open Fake.Core

// Default target
let defaultTask = BuildTask.create "Default" [] {
  Trace.trace "Hello World from FAKE"
}

// start build
BuildTask.runOrDefault defaultTask
```


```fsharp
#r "paket:
nuget BlackFox.Fake.BuildTask
nuget Fake.IO.FileSystem
nuget Fake.Core.Target //"
#load "./.fake/build.fsx/intellisense.fsx"

open BlackFox.Fake
open Fake.Core
open Fake.IO

// Properties
let buildDir = "./build/"

// Targets
let cleanTask = BuildTask.create "Clean" [] {
  Shell.CleanDir buildDir
}

let defaultTask = BuildTask.create "Default" [cleanTask] {
  Trace.trace "Hello World from FAKE"
}

// start build
BuildTask.runOrDefault defaultTask
```
