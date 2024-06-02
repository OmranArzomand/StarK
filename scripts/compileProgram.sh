#!/bin/bash

if [ $# -lt 2 ] ; then
  echo "USAGE: $0 <compiler directory> <program path> <compiled jar path>"
  exit 1
fi

COMPILER_DIR="$1"
FILE_PATH="$2"
JAR_PATH="$3"

export JAVA_OPTS="" 

`timeout 180 java $JAVA_OPTS -jar "$COMPILER_DIR/kotlinc/lib/kotlin-compiler.jar" "$FILE_PATH" -include-runtime -d "$JAR_PATH"`
exit_code="$?"
exit "$exit_code"

