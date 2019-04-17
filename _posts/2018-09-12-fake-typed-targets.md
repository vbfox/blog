---
layout: post
title: "Replacing FAKE target strings with types"
tags: F#, FAKE, Build, DevOps
date: 2018-09-12
---

After years of usage I started to find [FAKE](https://fake.build/)'s `Target` syntax less expressive
than it could be.

I developed multiple variants of a "Task" library to replace it that was
available via gist, sometimes tweeting about it in answer to discussions but
never clearly releasing it.

With FAKE 5 moving to small modules it's the occasion to choose a good name
"`BuildTask`" and release it on
[NuGet](https://www.nuget.org/packages/BlackFox.Fake.BuildTask/) with the source code on
[GitHub](https://github.com/vbfox/FoxSharp/tree/master/src/BlackFox.Fake.BuildTask).

## What does BuildTask changes

### Strongly-Typed targets

`Target` has a very stringly-typed API, strings are used everywhere as identifiers, with the consequence that their
value is only verified when the script is executed.

```fsharp
Target.create "Default" (fun _ ->
  (* ... *)
)

Target.runOrDefault "Defautl"
```

In `BuildTask` each created task returns a value that represent it and the compiler check the value usage as with any
other variable.

```fsharp
let defaultTask = BuildTask.createFn "Default" [] (fun _ ->
  (* ... *)
)

BuildTask.runOrDefault defaultTask
```

### Default syntax using computation expressions

While FAKE `Target.create` expect a function as parameter `BuildTask.create` uses a computation expression to do the
same (Like [Expecto](https://github.com/haf/expecto#writing-tests)), removing a little bit of verbosity for each target:

```fsharp
Target.create "Default" (fun _ ->
  (* ... *)
)
```

```fsharp
BuildTask.create "Default" [] {
  (* ... *)
}
```

*Note: `BuildTask.createFn` still provide the function-syntax if you need it.*

### Dependencies

The biggest change is the dependency syntax, `Target` rely on operators chaining
(or methods doing the same) and the result looks good for linear dependencies:

```fsharp
"Clean"
 ==> "BuildApp"
 ==> "BuildTests"
 ==> "Test"
 ==> "PackageApp"
 ==> "Default"
 ==> "CI"
```

But the dependencies here are simplified, they don't reflect the reality of target dependencies.
Clean shouldn't be mandatory except on CI, packaging the app shouldn't mandate running the tests and building the
tests shouldn't require building the app.

The real dependencies are more like:

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

And while the linear version was pretty readable, it isn't the case here.

The reason is that we are defining a directed acyclic graph by listing its edges, but there is another text
representation of a DAG that is much more readable: listing all preceding vertex for each vertex.

It's a syntax that is already used by tools similar to FAKE like [Gulp](https://gulpjs.com/) :

```js
gulp.task("css", function() { /* ...*/ });
gulp.task("js", function() { /* ...*/ });
gulp.task("test", ["js"], function() { /* ...*/ });
gulp.task("default", ["css", "test"], function() { /* ...*/ });
```

`BuildTask` uses a similar syntax:

```fsharp
let clean = BuildTask.create "Clean" [] { (* ... *) }

let buildApp = BuildTask.create "BuildApp" [clean.IfNeeded] { (* ... *) }
let packageApp = BuildTask.create "PackageApp" [buildApp] { (* ... *) }

let buildTests = BuildTask.create "BuildTests" [clean.IfNeeded] { (* ... *) }
let test = BuildTask.create "Test" [buildTests] { (* ... *) }

let defaultTask = BuildTask.createEmpty "Default" [packageApp; test]
let ci = BuildTask.createEmpty "CI" [clean; defaultTask]
```

### Ordering

The direct consequence of the strongly-typed syntax along with the dependency syntax is that `BuildTask` enforces a
strict ordering of the build script. Exactly as F# requires for functions inside a module.

While I feared this consequence at first, after converting quite a lot of FAKE scripts it's easy to adopt and
make the build script order more logical for developers familiar with F#.

## Getting started samples

Here are a few of the samples on the FAKE getting started page ported to `BuildTask`:

[GETTING STARTED](https://fake.build/fake-gettingstarted.html#Getting-started):

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

[CLEANING THE LAST BUILD OUTPUT](https://fake.build/fake-gettingstarted.html#Cleaning-the-last-build-output):

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

## Conclusion

I invite any FAKE user whenever they like the current syntax or not to try it
([NuGet](https://www.nuget.org/packages/BlackFox.Fake.BuildTask/)) and tell me what they think on
[twitter](https://twitter.com/virtualblackfox) or in a
[GitHub](https://github.com/vbfox/FoxSharp/tree/master/src/BlackFox.Fake.BuildTask) issue.
