@echo off

pushd build
dotnet run --project build.fsproj -- %*
popd