#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")"

dotnet run --project build.fsproj -- $@