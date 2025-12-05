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

#Download build_meta.json and import only the keys we expect. Avoid shell
#eval-style expansion so a malicious JSON cannot inject environment changes.
build_meta=$(retry_curl -s -L "$1")
allowed_keys=(
  "jcef_repository"
  "jcef_commit"
  "jcef_commit_long"
  "jcef_url"
  "cef_version"
  "release_tag"
  "release_url"
  "download_url_linux_amd64"
  "download_url_linux_arm64"
  "download_url_macosx_amd64"
  "download_url_macosx_arm64"
  "download_url_windows_amd64"
  "download_url_windows_arm64"
)

for key in "${allowed_keys[@]}"; do
  if ! value=$(printf '%s' "$build_meta" | jq -er --arg key "$key" '.[$key] | tostring'); then
    echo "Missing required key '$key' in build_meta.json" >&2
    exit 1
  fi
  export "$key=$value"
done

#Set JOGL information
export jogl_build=2.5.0
export jogl_download=https://jogamp.org/deployment/v2.5.0/jar #Without terminating /!
export jogl_git=https://jogamp.org/cgit/jogl.git
export jogl_commit=70f62ca5d121e5e71548246d468b5e7baa5faf25 #From META-INF
export gluegen_git=https://jogamp.org/cgit/gluegen.git
export gluegen_commit=a235ae5dae463afa16f62f48bf62f896efa80b68 #From META-INF

#Set jcefmaven information
export mvn_version=$2
