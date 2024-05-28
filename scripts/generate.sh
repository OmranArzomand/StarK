#!/bin/bash

if [ $# -lt 1 ] ; then
  echo "USAGE: $0 <generator config directory> <output location>"
  exit 1
fi

OUTPUT=`time timeout 100 java -ea -cp "../generators/StarSmith.jar":"$1/out/classes" kotlin --count 1 --out $2`
exit_code="$?"
echo "${OUTPUT}"
echo "Hello"
exit "$exit_code"

