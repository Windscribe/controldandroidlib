#!/bin/bash

# This script is used to locally build an iOS .xcframework from ctrld source using the go mobile tool.

# Requirements:
#   - Xcode 15 + Build tools
#   - Go 1.21
#   - Git
# Usage: $ ./build_ctrld_ios.sh 1.4.1

TAG="$1"
if [ -z "$TAG" ]; then
    echo "Usage: $0 <version-tag>"
    exit 1
fi

# Set the PATH for Go binaries
export PATH="$PATH:$HOME/go/bin"

# Clean up previous builds
if [ -d "bin" ]; then
    rm -rf bin
fi
mkdir -p bin
cd bin || exit
root=$(pwd)

# Clean up previous ctrld repo if it exists
if [ -d "ctrld" ]; then
    rm -rf ctrld
fi

# Clone the repository and checkout the specified tag
git clone --depth 1 --branch "$TAG" --single-branch https://gitlab.int.windscribe.com/controld/clients/ctrld.git

# Check if the clone was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone the repository."
    exit 1
fi

# Prepare gomobile tool
sourcePath="./ctrld/cmd/ctrld_library"
cd "$sourcePath" || exit

# Install gomobile tool
go install golang.org/x/mobile/cmd/gomobile@latest
go get golang.org/x/mobile/bind
gomobile init

# Prepare build info
buildDir="$root/../Build"
mkdir -p "$buildDir"
COMMIT=$(git rev-parse HEAD)

# Set linker flags with version and commit info
ldflags="-s -w -X gitlab.int.windscribe.com/controld/clients/ctrld.git/cmd/cli.version=v$TAG -X gitlab.int.windscribe.com/controld/clients/ctrld.git/cmd/cli.commit=$COMMIT"

# Build
gomobile bind -ldflags="$ldflags" -target=ios -o "$buildDir/Ctrld.xcframework"
if [ $? -ne 0 ]; then
    echo "Error: Failed to build the Ctrld library."
    exit 1
fi

# Clean up
rm -rf "$root"
echo "Successfully built Ctrld library $TAG ($COMMIT)."