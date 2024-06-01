#!/bin/bash

source "$HOME/.sdkman/bin/sdkman-init.sh"
if [ $# -lt 1 ] ; then
  echo "USAGE: $0 <generator config directory> <output location>"
  exit 1
fi
sdk use java 11.0.23-amzn
java --version
cd ../../bbfgradle
OUTPUT=`time ./gradlew runBBF`
exit_code="$?"

cd ../StarKSmith/scripts
DIR=$(dirname "$2")
mkdir -p "$DIR"
cp ../../bbfgradle/tmp/tmp.kt "$2"
echo "${OUTPUT}"
exit "$exit_code"

