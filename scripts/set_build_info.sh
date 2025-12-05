#!/bin/bash
set -euo pipefail

if [ ! $# -eq 2 ]
  then
    echo "Usage: ./set_build_info.sh <build_meta_url> <mvn_version>"
    echo ""
    echo "build_meta_url: The url to download build_meta.json from"
    echo "mvn_version: The maven version to export to"
    exit 1
fi

script_dir=$(cd "$( dirname "$0" )" && pwd)
. "$script_dir/lib/retry.sh"

#Print build meta location
echo "Initializing for build from $1 for $2..."

#Download build_meta.json and import to local environment
export $(retry_curl -s -L "$1" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]")

#Set JOGL information
export jogl_build=2.5.0
export jogl_download=https://jogamp.org/deployment/v2.5.0/jar #Without terminating /!
export jogl_git=https://jogamp.org/cgit/jogl.git
export jogl_commit=70f62ca5d121e5e71548246d468b5e7baa5faf25 #From META-INF
export gluegen_git=https://jogamp.org/cgit/gluegen.git
export gluegen_commit=a235ae5dae463afa16f62f48bf62f896efa80b68 #From META-INF

#Set jcefmaven information
export mvn_version=$2
