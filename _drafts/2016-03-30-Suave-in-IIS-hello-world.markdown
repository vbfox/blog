---
layout: post
title: "Suave in IIS - Hello world"
tags: Suave F# IIS
---

Start with hello world :

```fsharp
open Suave

[<EntryPoint>]
let main argv =
    startWebServer defaultConfig (Successful.OK "Hello World!")
    0
```

Configure platform helper in IIS, install via web installer, enable handler mapping feature delegation, authorize `IIS_IUSRS` to access bin folder.

web.config :

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
Access magic `HTTP_PLATFORM_PORT` :

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

configure Hello world

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

it works