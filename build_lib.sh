#!/bin/bash

# This script is used to locally build Android .aar library and iOS .xcframework from ctrld source using go mobile tool.

# Requirements:
#   - Android NDK (version 23+)
#   - Android SDK (version 33+)
#   - Xcode 15 + Build tools
#   - Go 1.21
#   - Git
# usage: $ ./build_lib.sh v1.3.4

TAG="$1"
export PATH=$PATH:~/go/bin
mkdir bin
cd bin || exit
root=$(pwd)

# Get source from GitHub and switch to the specified tag
git clone --depth 1 --branch "$TAG" https://github.com/Control-D-Inc/ctrld.git

# Prepare gomobile tool
sourcePath=./ctrld/cmd/ctrld_library
cd $sourcePath || exit
go install golang.org/x/mobile/cmd/gomobile@latest
go get golang.org/x/mobile/bind
gomobile init

# Prepare build info
buildDir=$root/../build
mkdir -p "$buildDir"
COMMIT=$(git rev-parse HEAD)

# Set linker flags with version and commit info
ldflags="-s -w -X gitlab.int.windscribe.com/controld/clients/ctrld.git/cmd/cli.version=$TAG -X gitlab.int.windscribe.com/controld/clients/ctrld.git/cmd/cli.commit=$COMMIT"

# Build
gomobile bind -ldflags="$ldflags" -o "$buildDir"/ctrld.aar || exit

# Clean up
rm -r "$root"
echo "Successfully built Ctrld library $TAG ($COMMIT)."