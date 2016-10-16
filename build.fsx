#r "packages/FAKE/tools/FakeLib.dll"
#r "packages/WinSCP/lib/WinSCPnet.dll"

open Fake
open WinSCP
open System
open System.IO
open System.Diagnostics

module WindowsPath =
    open System
    open System.IO

    let path = lazy (Environment.GetEnvironmentVariable("PATH").Split(';') |> List.ofArray)
    let pathExt = lazy (Environment.GetEnvironmentVariable("PATHEXT").Split(';') |> List.ofArray)

    let find names =
        path.Value
        |> Seq.collect (fun dir -> names |> List.map (fun name -> Path.Combine(dir, name)))
        |> Seq.tryFind(File.Exists)

    let findProgram name =
        pathExt.Value
        |> List.map ((+) name)
        |> find

let rootDir = Path.GetFullPath(__SOURCE_DIRECTORY__)

let getBundlePath() =
    match WindowsPath.findProgram "bundle" with
    | Some(p) -> p
    | None -> failwith "Bundle not found"

let execBundle args =
    let config (psi:ProcessStartInfo) =
        psi.FileName <- getBundlePath()
        psi.Arguments <- args
    let result = ExecProcess config (TimeSpan.FromMinutes(5.))
    if result <> 0 then failwith "Bundle failed"

Target "Install" <| fun _ ->
    execBundle ""

Target "Build" <| fun _ ->
    execBundle "exec jekyll build"

Target "Serve" <| fun _ ->
    execBundle "exec jekyll serve --future --drafts --watch"

let private winScpPath =
    lazy (
        let assemblyDir = Path.GetDirectoryName(typedefof<Session>.Assembly.Location)
        Path.Combine(assemblyDir, "..", "content", "WinSCP.exe")
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
        raise (new AggregateException(exceptions))

let envVarOrAskUser name question =
    match environVarOrNone name with
    | Some x -> x
    | None -> getUserPassword question

Target "Upload" <| fun _ ->
    let options = new SessionOptions()
    options.Protocol <- Protocol.Ftp
    options.FtpSecure <- FtpSecure.Explicit
    options.FtpMode <- FtpMode.Active
    options.HostName <- "vbfox.net"
    options.UserName <- "blog_upload"
    options.Password <- envVarOrAskUser "password" "FTP Password: "
    uploadFolder (rootDir </> "_site") "/" options

Target "CI" DoNothing

"Install" ?=> "Build"
"Install" ?=> "Serve"
"Build" ==> "Upload"

"Install" ==> "CI"
"Upload" ==> "CI"

RunTargetOrDefault "Build"
