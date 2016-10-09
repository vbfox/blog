---
layout: post
title: "First release for MasterOfFoo"
tags: F# MasterOfFoo
---

MasterOfFoo is an F# library that intend to facilitate writing functions that act like the native `printf` one does.

I presented it as an experiment during september's [Paris F# Meetup][meetup] (See [the summary][sept_meetup] in french)
but I feel like it's now ready to be tested by more people.

It is now available [on nuget][nuget] as a preview version of 0.1.2 and the source code is on [GitHub][github].

The API is described in more details in the [readme][readme] but here is a small taste of the possibilities with a
proof-of-concept `sqlCommandf` implementation :

```fsharp
module SqlCommandBuilder =
    open System.Text
    open BlackFox.MasterOfFoo
    open System.Data.Common
    open System.Data.SqlClient

    type internal SqlEnv<'Result, 'cmd when 'cmd :> DbCommand>(command: 'cmd, k) =
        inherit PrintfEnv<unit, unit, 'Result>(())
        let queryString = StringBuilder()
        let mutable index = 0

        override __.Finalize(): 'Result =
            command.CommandText <- queryString.ToString()
            k(command)

        override __.Write(s : PrintableElement) =
            let asPrintf = s.FormatAsPrintF()
            match s.ElementType with
            | PrintableElementType.FromFormatSpecifier ->
                let parameter =
                    if typeof<DbParameter>.IsAssignableFrom(s.ValueType) then
                        s.Value :?> DbParameter
                    else
                        let paramName = sprintf "@p%i" index
                        index <- index + 1

                        let parameter = command.CreateParameter()
                        parameter.ParameterName <- paramName
                        parameter.Value <- s.Value
                        parameter

                ignore(queryString.Append parameter.ParameterName)
                command.Parameters.Add parameter |> ignore
            | _ ->
                ignore(queryString.Append asPrintf)

        override __.WriteT(()) = ()

    let sqlCommandf (format : Format<'T, unit, unit, SqlCommand>) =
        doPrintfFromEnv format (SqlEnv(new SqlCommand (), id))

    let sqlRunf (connection: SqlConnection) (format : Format<'T, unit, unit, unit>) =
        let execute (cmd: SqlCommand) = cmd.ExecuteNonQuery() |> ignore
        doPrintfFromEnv format (SqlEnv(connection.CreateCommand(), execute))

// Create the parametrized query "SELECT * FROM users WHERE name=@p0"
let cmd = sqlCommandf "SELECT * FROM users WHERE name=%s" "vbfox"

sqlRunf connection "DELETE FROM users WHERE name=%s" "vbfox"
```

[meetup]: https://www.meetup.com/Functional-Programming-in-F/
[sept_meetup]: https://fsharpparis.github.io/partagez-ce-que-vous-avez-fait-en-F-sharp/
[readme]: https://github.com/vbfox/MasterOfFoo/blob/master/Readme.md
[github]: https://github.com/vbfox/MasterOfFoo
[nuget]: https://www.nuget.org/packages/BlackFox.MasterOfFoo