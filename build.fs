module BlackFox.Blog.Build.Program

open System
open System.IO
open System.Reflection

open BlackFox
open BlackFox.Fake
open BlackFox.CommandLine
open Fake.Core
open Fake.IO.FileSystemOperators
open Fake.BuildServer
open WinSCP

let createAndGetDefault () =
    let rootDir = Path.GetFullPath(__SOURCE_DIRECTORY__)

    let getBundlePath() =
        match PathEnvironment.findExecutable "bundle" false with
        | Some(p) -> p
        | None -> failwith "Bundle not found"

    let execBundle (args: CmdLine) =
        let p = CreateProcess.fromRawCommandLine (getBundlePath()) (args.ToString())
        let result = Proc.run p
        if result.ExitCode <> 0 then failwith "Bundle failed"

    let installTask = BuildTask.create "Install" [] {
        execBundle CmdLine.empty
    }

    let drafts = Environment.environVarOrNone "DRAFTS" <> None
    let future = Environment.environVarOrNone "FUTURE" <> None

    let buildTask = BuildTask.create "Build" [installTask.IfNeeded] {
        let cmdLine =
            CmdLine.fromList ["exec"; "jekyll"; "build"]
            |> CmdLine.appendIf drafts "--drafts"
            |> CmdLine.appendIf future "--future"
        execBundle cmdLine
    }

    let serveTask = BuildTask.create "Serve" [installTask.IfNeeded] {
        let cmdLine =
            CmdLine.fromList ["exec"; "jekyll"; "build"; "--future"; "--drafts"; "--watch"]
        execBundle cmdLine
    }

    let winScpPath =
        lazy (
            let assemblyDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)
            Path.Combine(assemblyDir, "WinSCP.exe")
        )

    let uploadFolder localDir remoteDir (options: SessionOptions) =
        use session = new Session()
        session.ExecutablePath <- winScpPath.Value
        session.Open options

        let localPath = Path.Combine(localDir, "*")
        printfn "Uploading the content of '%s' to '%s' on '%s'" localPath remoteDir options.HostName
        let result = session.PutFiles(localPath, remoteDir)

        if not result.IsSuccess then
            let exceptions = result.Failures |> Seq.map (fun e -> e :> Exception)
            raise (AggregateException(exceptions))

    let envVarOrAskUser name question =
        match Environment.environVarOrNone name with
        | Some x -> x
        | None -> UserInput.getUserPassword question

    let uploadTask = BuildTask.create "Upload" [buildTask] {
        let options = SessionOptions()
        options.Protocol <- Protocol.Ftp
        options.FtpSecure <- FtpSecure.Explicit
        options.FtpMode <- FtpMode.Active
        options.HostName <- "vbfox.net"
        options.UserName <- "blog_upload"
        options.Password <- envVarOrAskUser "password" "FTP Password: "
        uploadFolder (rootDir </> "_site") "/" options
    }

    let _ciTask = BuildTask.createEmpty "CI" [installTask; uploadTask]

    let defaultTask = BuildTask.createEmpty "Default" [buildTask]

    defaultTask

[<EntryPoint>]
let main argv =
    BuildTask.setupContextFromArgv argv
    BuildServer.install [ AppVeyor.Installer; TeamFoundation.Installer ]

    let defaultTask = createAndGetDefault()
    BuildTask.runOrDefaultApp defaultTask