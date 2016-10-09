---
layout: post
title: "ColoredPrintf released"
tags: F#, MasterOfFoo, ColoredPrintf
date: 2016-10-10 00:00
---

ColoredPrintf is a very simple library that provide a `printf`-like function with color support. A first version
of the library is available on [NuGet][nuget] with it's source code on my [Github][github].

The syntax to use for color is `$foreground;background[text]` with the color names being the same as in the
[ConsoleColor][consolecolor] enumeration.

The main entry points of the library are the `coloredprintf` and `coloredprintfn` functions that have the same
signature as printf (It uses my [MasterOfFoo][masteroffoo] library for that).

Example
-------

```fsharp
colorprintfn "Hello $red[world]."
colorprintfn "Hello $green[%s]." "user"
colorprintfn "$white[Progress]: $yellow[%.2f%%] (Eta $yellow[%i] minutes)" 42.33 5
colorprintfn "$white;blue[%s ]$black;white[%s ]$white;red[%s]" "La vie" "est" "belle"
```

![result](/assets/coloredprintf-sample.png)

[github]: https://github.com/vbfox/ColoredPrintf
[nuget]: https://www.nuget.org/packages/BlackFox.ColoredPrintf
[consolecolor]: https://msdn.microsoft.com/en-us/library/system.consolecolor(v=vs.110).aspx
[masteroffoo]: https://github.com/vbfox/MasterOfFoo