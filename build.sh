#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")/build"

dotnet run --project build.fsproj -- $@