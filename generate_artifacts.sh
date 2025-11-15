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

if command -v id >/dev/null 2>&1; then
  HOST_UID=$(id -u)
  HOST_GID=$(id -g)
else
  HOST_UID=1000
  HOST_GID=1000
fi

#CD to main dir of this repository
cd "$( dirname "$0" )"

#Clean output dir
rm -rf out
mkdir -p out

#Run docker build (force rebuild to pick up script changes)
docker compose -f docker-compose.yml up --build

#Fix permissions on exported artifacts coming from the container
docker compose -f docker-compose.yml run --rm --no-deps --entrypoint chown generate-artifacts -R "${HOST_UID}:${HOST_GID}" /jcefout

#Organize exported artifacts on host
bash scripts/organize_out.sh out
