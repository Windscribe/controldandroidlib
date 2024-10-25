#!/bin/bash

# This script is used to locally build OS .xcframework from ctrld source using the go mobile tool.

# Requirements:
#   - Xcode 15 + Build tools
#   - Go 1.21
#   - Git
# usage: $ ./build_lib.sh v1.3.4

TAG="$1"
if [ -z "$TAG" ]; then
    echo "Usage: $0 <version-tag>"
    exit 1
fi

# Hacky way to replace version info.
update_versionInfo() {
    local file="$1/ctrld/cmd/cli/cli.go"
    local tag="$2"
    local commit="$3"
    awk -v tag="$tag" -v commit="$commit" '
        BEGIN { version_updated = 0; commit_updated = 0 }
        /^\tversion/ {
            sub(/= ".+"/, "= \"" tag "\"");
            version_updated = 1;
        }
        /^\tcommit/ {
            sub(/= ".+"/, "= \"" commit "\"");
            commit_updated = 1;
        }
        { print }
        END {
            if (version_updated == 0) {
                print "\tversion = \"" tag "\"";
            }
            if (commit_updated == 0) {
                print "\tcommit = \"" commit "\"";
            }
        }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

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
git clone --depth 1 --branch "$TAG" --single-branch https://github.com/Control-D-Inc/ctrld.git

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
buildDir="$root/../Sources"
mkdir -p "$buildDir"
COMMIT=$(git rev-parse HEAD)
update_versionInfo "$root" "$TAG" "$COMMIT"
ldflags="-s -w"

# Build
gomobile bind -ldflags="$ldflags" -target=ios -o "$buildDir/Ctrld.xcframework"
if [ $? -ne 0 ]; then
    echo "Error: Failed to build the Ctrld library."
    exit 1
fi

# Clean up
rm -rf "$root"
echo "Successfully built Ctrld library $TAG ($COMMIT)."