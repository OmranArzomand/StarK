#!/bin/bash

if [ $# -lt 3 ] ; then
  echo "USAGE: $0 <kotlin compiler directory> <kotlin programs directory> <html coverage report directory>"
  exit 1
fi

COMPILER_DIR="$1"
PROG_DIR="$2"
HTML_OUTPUT_DIR="$3"

export JAVA_OPTS="-javaagent:../kover/kover-jvm-agent-0.8.0.jar=file:../kover/agent.args" 

rm ../output/tmp/kover-report.ic

for file in "$PROG_DIR"/*; do
  java $JAVA_OPTS -jar "$COMPILER_DIR/kotlinc/lib/kotlin-compiler.jar" "$file" -include-runtime -d ../output/tmp/hello.jar
done

rm -rf "$HTML_OUTPUT_DIR"
mkdir "$HTML_OUTPUT_DIR"

java -jar ../kover/kover-cli-0.8.0.jar report ../output/tmp/kover-report.ic --classfiles "$COMPILER_DIR/kotlinc/lib/filtered-kotlin-compiler.jar" --src ../output/tmp --html "$HTML_OUTPUT_DIR"


