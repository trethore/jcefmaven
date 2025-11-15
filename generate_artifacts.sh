#!/bin/bash

if [ ! $# -eq 2 ]
  then
    echo "Usage: ./generate_artifacts.sh <build_meta_url> <mvn_version>"
    echo ""
    echo "build_meta_url: The url to download build_meta.json from"
    echo "mvn_version: The maven version to export to"
    exit 1
fi

export BUILD_META_URL=$1
export MVN_VERSION=$2

# Ensure docker containers run with the current host user to keep artifacts writable.
if command -v id >/dev/null 2>&1; then
  export JCEF_UID=${JCEF_UID:-$(id -u)}
  export JCEF_GID=${JCEF_GID:-$(id -g)}
else
  export JCEF_UID=${JCEF_UID:-1000}
  export JCEF_GID=${JCEF_GID:-1000}
fi

#CD to main dir of this repository
cd "$( dirname "$0" )"

#Clean output dir
rm -rf out
mkdir -p out

#Run docker build (force rebuild to pick up script changes)
docker compose -f docker-compose.yml up --build

#Organize exported artifacts on host
bash scripts/organize_out.sh out
