#!/bin/bash
set -euo pipefail

if [ ! $# -eq 4 ]
  then
    echo "Usage: ./generate_natives.sh <bit> <platform> <release_tag> <artifact_url>"
    echo ""
    echo "bit: linux32, linux64, macos64, win32 or win64"
    echo "platform: name of the platform to release for (e.g. linux-amd64)"
    echo "release_tag: the tag of the release (jcef+X+cef+Y)"
    echo "artifact_url: URL to download artifact from"
    exit 1
fi

#CD to base dir of this repository
cd "$( dirname "$0" )" && cd ..

#Clear build dir
rm -rf build
mkdir build
cd build

echo "Creating natives for $2 with tag $3..."
export platform=$2
export release_download_url=$4

#Fetch artifact
echo "Fetching artifact for $2..."
curl -fsSL -o artifact.tar.gz "$4"

#Extract artifact
echo "Extracting..."
gzip -t artifact.tar.gz
tar -zxf artifact.tar.gz
rm artifact.tar.gz

#Relocate and prune the files for maven packaging
echo "Building package..."
rm -f compile.sh compile.bat README.txt run.sh run.bat
if [ "$1" == "macos64" ] ; then
  mv bin/jcef_app.app/Contents/Frameworks/* .
  mv bin/jcef_app.app/Contents/Java/libjcef.dylib .
  JOGAMP_NATIVE_JARS="bin/jcef_app.app/Contents/Java/*gluegen-rt-natives*.jar bin/jcef_app.app/Contents/Java/*jogl-all-natives*.jar"
  JOGAMP_JARS_DIR="bin/jcef_app.app/Contents/Java"
else
  mv bin/lib/$1/* .
  JOGAMP_NATIVE_JARS="bin/*gluegen-rt-natives*.jar bin/*jogl-all-natives*.jar"
  JOGAMP_JARS_DIR="bin"
fi

# Extract JogAmp natives (gluegen/jogl) from the upstream bundle so OSR works.
# The upstream tar ships the native jars in bin/, not under bin/lib/$bit, so we
# need to unpack them explicitly or the DLLs/SOs never make it into our tar.gz.
extract_jogamp_natives() {
  local jar
  for jar in $JOGAMP_NATIVE_JARS; do
    [ -f "$jar" ] || continue
    echo "Including JogAmp natives from $(basename "$jar")..."
    unzip -q "$jar" -x "META-INF/*" -d .
  done
  # Flatten everything from "natives" to the bundle root so java.library.path can find it.
  if [ -d natives ]; then
    find natives -type f -exec mv -f {} . \; 2>/dev/null || true
    rm -rf natives
  fi
}
extract_jogamp_natives

# Fail fast if we somehow lost the core native we need for JOGL OSR.
if ! ls *gluegen*rt* >/dev/null 2>&1; then
  echo "ERROR: gluegen_rt native was not bundled; aborting." >&2
  exit 1
fi

rm -rf bin docs tests

#Generate a readme file
./../scripts/fill_template.sh ../templates/natives/README.txt README.txt

#Generate a build_meta file
./../scripts/fill_template.sh ../templates/natives/build_meta.json build_meta.json

#Compress contents
echo "Compressing package (1/2)..."
tar -zcf jcef-natives-$2-$3.tar.gz *

#Generate sources and javadoc
echo "Generating sources and javadoc..."
mkdir compile
./../scripts/fill_template.sh ../templates/natives/pom.xml compile/pom.xml
cp -r ../templates/natives/src compile
./../scripts/fill_template.sh ../templates/natives/src/main/java/me/tytoo/jcefmaven/CefNativeBundle.java compile/src/main/java/me/tytoo/jcefmaven/CefNativeBundle.java
cd compile
mvn -B -ntp -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn clean package source:jar javadoc:jar
cd ..

echo "Exporting artifacts (2/4)..."
mv compile/target/jcef-natives-$2-$3-sources.jar /jcefout
mv compile/target/jcef-natives-$2-$3-javadoc.jar /jcefout

#Extracting native class and throw away compile dir
unzip compile/target/jcef-natives-$2-$3.jar
rm -f META-INF/INDEX.LIST
rm -rf compile

#Compress contents
echo "Compressing package (2/2)..."
zip -r jcef-natives-$2-$3.jar jcef-natives-$2-$3.tar.gz me META-INF

#Generate a pom file
echo "Generating pom..."
./../scripts/fill_template.sh ../templates/natives/pom.xml jcef-natives-$2-$3.pom

#Move built artifacts to export dir
echo "Exporting artifacts (4/4)..."
mv jcef-natives-$2-$3.jar /jcefout
mv jcef-natives-$2-$3.pom /jcefout

#Done
echo "Done generating natives for $2-$3"
