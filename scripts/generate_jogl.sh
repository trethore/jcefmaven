#!/bin/bash

set -euo pipefail

if [ ! $# -eq 1 ]
  then
    echo "Usage: ./generate_jogl.sh <artifact>"
    echo ""
    echo "artifact: the artifact to create (e.g. jogl-all or gluegen-rt)"
    exit 1
fi

artifact=$1
repo_root=$(cd "$( dirname "$0" )/.." && pwd)
friwi_base="https://repo.maven.apache.org/maven2/me/friwi/$artifact/$jogl_build"
lib_dir="$repo_root/libs/$artifact"

stage_artifact () {
  local name=$1
  local dest=$2
  if [ -f "$lib_dir/$name" ]; then
    echo "Using cached $lib_dir/$name"
    cp "$lib_dir/$name" "$dest"
  else
    local url="$friwi_base/$name"
    echo "Downloading $url"
    curl -fsSL "$url" -o "$dest"
  fi
}

#Prepare build dir
cd "$repo_root"
rm -rf build
mkdir build
cd build

echo "Staging $artifact version $jogl_build..."
stage_artifact "$artifact-$jogl_build.jar" "$artifact-$jogl_build.jar"
stage_artifact "$artifact-$jogl_build-sources.jar" "$artifact-$jogl_build-sources.jar"
stage_artifact "$artifact-$jogl_build-javadoc.jar" "$artifact-$jogl_build-javadoc.jar"

echo "Generating pom..."
./../scripts/fill_template.sh ../templates/$artifact/pom.xml $artifact-$jogl_build.pom

echo "Exporting artifacts..."
mv $artifact-$jogl_build.jar /jcefout
mv $artifact-$jogl_build-sources.jar /jcefout
mv $artifact-$jogl_build-javadoc.jar /jcefout
mv $artifact-$jogl_build.pom /jcefout

echo "Done generating $artifact with version $jogl_build"
