---
layout: post
title: "Suave in IIS - Hello world"
tags: Suave F# IIS Proxy
---

[Suave](https://suave.io/) is an open source F# library implementing a web server in a
functional style.
The source code is on [GitHub](https://github.com/SuaveIO/suave) and releases are available
on [NuGet](http://www.nuget.org/packages/Suave) like most .NET open source projects these days.

You can find the full sample presented here as a Visual Studio 2015 project
[on my GitHub](https://github.com/vbfox/SuaveIIS). I'm using [Paket](https://fsprojects.github.io/Paket/)
to get the `Suave` package but the standard NuGet UI would work as well (albeit slower).

The minimal hello world is simply :

```fsharp
open Suave

[<EntryPoint>]
let main argv =
    startWebServer defaultConfig (Successful.OK "Hello World!")
    0
```

`startWebServer` is a bloking function that take two parameters:

* A `SuaveConfig` object defining the configuration, the default one opens a single non encrypted
  server on port 8083.
* A `WebPart` representing everything that would be served.
  The type is actually an alias for `HttpContext -> Async<HttpContext option>` and suave provide
  a lot of filters & combinators to do standard things, like for example returning something
  different depending on the URL (Kinda expected for a web server).

Maybe i'll blog more about the different combinators and how to combine them to reproduce a few
common web server cases (Serving files, protecting access to some pages, ...) but as this post is
about IIS integration i'll keep the hello world code and build from that.

IIS
---

IIS is the Microsoft web server present by default on Windows Server & Desktops.
If you don't already have it on your dev machine it's available from the
*Turn Windows features on or off* in control panel. The entry is named
*Internet Information Services* and you can either go with the defaults or get
everything under there.

![Windows features](../assets/iis-windows-features.png)

Once installed, start IIS Manager and create a website listening on a random port on IP address
`127.0.0.1` with a *Physical path* corresponding to the `bin/Debug` directory of the hello world
project.

HttpPlatformHandler
-------------------

*HttpPlatformHandler* is an IIS addon that allow to use any http serving application where the
executable is able to receive the port to listen to via an environment variable.

To start the web site IIS run the executable with the `HTTP_PLATFORM_PORT` environment variable
containing the port that it need to listen to and the module will then proxy requests to this port
and sent back the response to the client. As the module insert itself inside the standard IIS
processing it mean that things like logging, https certificates, respawning the process when an
error happens or doing windows domain authentication can be handled by IIS without any change to
the application code.

To install it start the Web Platform Installer (Either from your start menu or from the right
side actions in IIS Manager) and search for it.

![Web Platform Installer](../assets/iis-httpplatformhandler.png)

To be able to enable it per-site like we'll do in the next step, open IIS Manager and in the
*Feature View* for the whole server, open *Feature Delegation* and enable *Handlers Mappings* as
**Read/Write**.

Using web.config
----------------

IIS expect it's configuration in an XML file named `web.config` so you'll need to add an xml file
named like that to your project with *Copy to Output Directory* configured to **Copy if newer**
with the content :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <handlers>
            <remove name="httpplatformhandler" />
            <add name="httpplatformhandler"
                path="*"
                verb="*"
                modules="httpPlatformHandler"
                resourceType="Unspecified" />
        </handlers>
        <httpPlatform processPath="./SuaveIIS.exe"
            arguments=""
            stdoutLogEnabled="true"
            stdoutLogFile="./SuaveIIS.log"
            startupTimeLimit="20"
            requestTimeout="00:05:00">
        </httpPlatform>
    </system.webServer>
</configuration>
```

This assume that your exectutable is named `SuaveIIS.exe` so adapt accordingly.

For this to work you'll also need to authorize IIS to read it, do to that open Explorer and
change the Permissions on the `bin` folder to allow read & write access by the local
`IIS_IUSRS` group.

Getting the port to listen to from F# Code
-------------------------------------------

In the current state, **HttpPlatformHandler** will start your executable, kill it after 20s
and restart it in a loop because it will never see it listening on it's specified port
so we need to read the port from the environment variable :

```fsharp
module IISHelpers =
    open System

    /// Port specified by IIS HttpPlatformHandler
    let httpPlatformPort =
        match Environment.GetEnvironmentVariable("HTTP_PLATFORM_PORT") with
        | null -> None
        | value ->
            match Int32.TryParse(value) with
            | true, value -> Some value
            | false, _ -> None
```

And then when we detect that we're started from IIS (Because `IISHelpers.httpPlatformPort`
is `Some`) we can configure Suave to listen locally on that port and nowhere else :

```fsharp
open Suave

[<EntryPoint>]
let main argv =
    let config = defaultConfig
    let config =
        match IISHelpers.httpPlatformPort with
        | Some port ->
            { config with
                bindings = [ HttpBinding.mkSimple HTTP "127.0.0.1" port ] }
        | None -> config

    startWebServer config (Successful.OK "Hello World!")
    0
```

If you compile it and visit your IIS site in a browser you should see your *Hello World*
being served by IIS.

Remarks
-------
* If you can't compile because the executable file is already it mean that your executable
is running in IIS. What you need to do is to remove the `web.config` file from the
`bin/Debug` directory, IIS will take this as a hint that your configuration changed and
that it need to stop using your binary.