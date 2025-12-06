#!/bin/bash
set -euo pipefail

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
artifactBase="${artifactId}-${version}"

#CD to the upload dir
script_dir=$(cd "$( dirname "$0" )" && pwd)
. "$script_dir/scripts/lib/retry.sh"
cd "$script_dir" && cd upload

if [ ! -f "${artifactBase}.jar" ]; then
  echo "ERROR: ${artifactBase}.jar not found in $(pwd); aborting upload."
  exit 1
fi
if [ ! -f "${artifactBase}.pom" ]; then
  echo "ERROR: ${artifactBase}.pom not found in $(pwd); aborting upload."
  exit 1
fi

pathGroupId=$(sed 's|\.|\/|g' <<< $groupId)
targetUrl=$repoUrl/$pathGroupId/$artifactId/$version/$artifactId-$version.jar

#Auth for GitHub packages if credentials are present (avoid unbound vars with set -u)
authArgs=()
if [[ -n "${GITHUB_USERNAME:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
  authArgs=(-u "$GITHUB_USERNAME:$GITHUB_TOKEN")
elif [[ -n "${GITHUB_ACTOR:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
  authArgs=(-u "$GITHUB_ACTOR:$GITHUB_TOKEN")
fi

#Prevent re-publishing versions that already exist.
status=$(retry_curl "${authArgs[@]}" -s -o /dev/null -w '%{http_code}' -I "$targetUrl" || true)
if [[ "$status" == "200" || "$status" == "206" || "$status" == "302" ]]; then
  echo "Artifact $artifactId-$version already pushed - skipping!"
  exit 0
elif [[ -n "$status" && "$status" =~ ^5 ]]; then
  echo "Artifact existence check got server error (HTTP $status); aborting." >&2
  exit 1
fi

echo "Pushing $artifactId-$version..."
# Use batch/CI-friendly Maven output to avoid extremely verbose transfer logs while keeping errors visible.
mvn -B -ntp -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
  deploy:deploy-file \
  -Durl=$repoUrl \
  -DrepositoryId=$repoId \
  -DpomFile=$artifactId-$version.pom \
  -Dfile=$artifactId-$version.jar \
  -Djavadoc=$artifactId-$version-javadoc.jar \
  -Dsources=$artifactId-$version-sources.jar

# Tidy up any legacy bundle artifacts if present
rm -rf me
rm -f central-bundle.zip
