#!/bin/bash

if [ ! $# -eq 5 ]
  then
    echo "Usage: ./upload_artifact.sh <repoUrl> <repoId> <groupId> <artifactId> <version>"
    echo "Repo url should NOT end in /!"
    exit 1
fi

repoUrl=$1
repoId=$2
groupId=$3
artifactId=$4
version=$5

#CD to the upload dir
cd "$( dirname "$0" )" && cd upload

pathGroupId=$(sed 's|\.|\/|g' <<< $groupId)
targetUrl=$repoUrl/$pathGroupId/$artifactId/$version/$artifactId-$version.jar

#Auth for GitHub packages if credentials are present
authArgs=()
if [[ -n "$GITHUB_USERNAME" && -n "$GITHUB_TOKEN" ]]; then
  authArgs=(-u "$GITHUB_USERNAME:$GITHUB_TOKEN")
elif [[ -n "$GITHUB_ACTOR" && -n "$GITHUB_TOKEN" ]]; then
  authArgs=(-u "$GITHUB_ACTOR:$GITHUB_TOKEN")
fi

#Prevent re-publishing versions that already exist
if curl "${authArgs[@]}" --output /dev/null --silent --fail -r 0-0 "$targetUrl"; then
    echo "Artifact $artifactId-$version already pushed - skipping!"
    exit 0
fi

echo "Pushing $artifactId-$version..."
mvn deploy:deploy-file -Durl=$repoUrl -DrepositoryId=$repoId -DpomFile=$artifactId-$version.pom -Dfile=$artifactId-$version.jar -Djavadoc=$artifactId-$version-javadoc.jar -Dsources=$artifactId-$version-sources.jar

