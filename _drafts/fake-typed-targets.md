---
layout: post
title: "Replacing FAKE target strings with types"
tags: F#, FAKE, Build, DevOps
---

I never really liked [FAKE](https://fake.build/) `Target` syntax and over the years
I developped multiple variants of a "Task" library to replace it that was available via gist, sometimes tweeting about it in answer to discussions but never clearly releasing it.

With FAKE 5 moving to small modules it's the occasion to choose a good name and release it on [NuGet](https://www.nuget.org/packages/BlackFox.Fake.BuildTask/).

## Why I don't like `Target`

There are a few points that I dislike and that `BuildTask` aim to solve.

### Dependencies

The main reason is the dependency syntax associated with it, `Target` doesn't specify it's dependencies directly but instead rely on operators chaining (or methods doing the same). The result only looks good for linear dependendencies :

```fsharp
"Clean"
 ==> "BuildApp"
 ==> "BuildTests"
 ==> "Test"
 ==> "PackageApp"
 ==> "Default"
 ==> "CI"
```

But the dependencies here are problematic, they don't reflect the reality of target dependencies. Clean shouldn't be mandatory except on CI, packaging the app shouldn't mandate running the tests and building the tests shouldn't require building the app.

The real dependencies are more like :

```fsharp
"Clean" =?> "BuildApp"
"Clean" =?> "BuildTests"
"Clean" ==> "CI"
"BuildApp" ==> "PackageApp"
"BuildTests" ==> "Test"
"PackageApp" ==> "Default"
"Test" ==> "Default"
"Default" ==> "CI"
```

And that's much less readable and I didn't even try to chain dependencies as it's even worse. 

The reason is that we are defining a directed acyclic graph by listing it's vertexes, but there is another text representation of a DAG that is much more readable: defining the parents of each cell as a list.

It's a syntax that is already used by tools similar to FAKE like [Gulp](https://gulpjs.com/) :

```js
gulp.task('css', function() { /* ...*/ });
gulp.task('js', function() { /* ...*/ });
gulp.task('test', ['js'], function() { /* ...*/ });
gulp.task('default', ['css', 'test'], function() { /* ...*/ });
```

### Stringly-Typed library

`Target` has a very stringly-typed API, strings are used everywhere as identifiers.
It's essentially like going back to an un-typed language, being forced to depend on runtime exceptions to avoid typos in identifiers :

```fsharp
Target.create "Default" (fun _ ->
  Trace.trace "Hello World from FAKE"
)

// start build
Target.runOrDefault "Defaulyt"
```

### 

using `BuildTask` the same dependencies are defined when the task is defined like that :

```fsharp
let clean = BuildTask.create "Clean" [] { (* ... *) }

let buildApp = BuildTask.create "BuildApp" [clean.IfNeeded] { (* ... *) }
let packageApp = BuildTask.create "PackageApp" [buildApp] { (* ... *) }

let buildTests = BuildTask.create "BuildTests" [clean.IfNeeded] { (* ... *) }
let test = BuildTask.create "Test" [buildTests] { (* ... *) }

let defaultTask = BuildTask.createEmpty "Default" [packageApp; test]
let ci = BuildTask.createEmpty "CI" [clean; defaultTask]
```

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
