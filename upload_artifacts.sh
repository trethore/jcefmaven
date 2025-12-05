#!/bin/bash
set -euo pipefail

if [ ! $# -eq 4 ]
  then
    echo "Usage: ./upload_artifacts.sh <build_meta_url> <repoUrl> <repo_id> <mvn_version>"
    echo "Repo url should NOT end in /!"
    exit 1
fi

#CD to dir of this script
cd "$( dirname "$0" )"

repoUrl=$2
repoId=$3

#Set build info
. scripts/set_build_info.sh $1 $4

#Move artifacts (jar/pom) to a non-protected folder, flattening structure
rm -rf upload
mkdir upload
find out -type f \( -name "*.jar" -o -name "*.pom" \) -print0 | while IFS= read -r -d '' file; do
  cp "$file" upload/
done

echo "Uploading GitHub Packages artifacts for $mvn_version..."

#Upload Jogamp libraries
./upload_artifact.sh $repoUrl $repoId me.tytoo jogl-all $jogl_build
./upload_artifact.sh $repoUrl $repoId me.tytoo gluegen-rt $jogl_build

#Upload API
./upload_artifact.sh $repoUrl $repoId me.tytoo jcef-api $release_tag

#Upload jcefmaven
./upload_artifact.sh $repoUrl $repoId me.tytoo jcefmaven $mvn_version

#Upload linux natives
./upload_artifact.sh $repoUrl $repoId me.tytoo jcef-natives-linux-amd64 $release_tag
./upload_artifact.sh $repoUrl $repoId me.tytoo jcef-natives-linux-arm64 $release_tag

#Upload windows natives
./upload_artifact.sh $repoUrl $repoId me.tytoo jcef-natives-windows-amd64 $release_tag

#Upload macosx natives
./upload_artifact.sh $repoUrl $repoId me.tytoo jcef-natives-macosx-amd64 $release_tag
./upload_artifact.sh $repoUrl $repoId me.tytoo jcef-natives-macosx-arm64 $release_tag

echo "Done uploading GitHub Packages artifacts!"
