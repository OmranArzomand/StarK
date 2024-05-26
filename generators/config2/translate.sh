#!/bin/bash

set -e
LC_NUMERIC="C.UTF-8"

COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;36m"
COLOR_NONE="\033[0m"

function print_step {
  printf "${COLOR_YELLOW}======[ ${1} ]======${COLOR_NONE}\n"
}

compile_args=$@

out_dirs=('kotlin')


# == TRANSLATE RUNTIME CLASSES
print_step "translate runtime classes"
javac -cp "./../StarSmith.jar":./ -d ./out/classes ./runtime/*.java



# == TRANSLATE SPECIFICATIONS
print_step "translate specifications"

java -Xss2m -ea -jar ./../StarSmith.jar --spec ./kotlin.ls --maxDepth 11 --allFeatures --toJava kotlin.java
mv ./kotlin.java ./out

javac -cp "./../StarSmith.jar":./ -d ./out/classes ./out/kotlin.java

