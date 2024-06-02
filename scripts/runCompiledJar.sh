#!/bin/bash

if [ $# -lt 1 ] ; then
  echo "USAGE: $0 <compiled jar path>"
  exit 1
fi

OUTPUT=`timeout 180 java $JAVA_OPTS -jar "$1"`
exit_code="$?"

export JAVA_OPTS="" 

echo "${OUTPUT}"
exit "$exit_code"