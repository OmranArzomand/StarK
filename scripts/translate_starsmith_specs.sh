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

GENERATORS_DIR="../generators"

for config in "$GENERATORS_DIR"/*; do
  if [ -d "$config" ]; then
    # == TRANSLATE RUNTIME CLASSES
    print_step "translate runtime classes"
    javac -cp "$GENERATORS_DIR/StarSmith.jar":./ -d "$config/out/classes" "$config"/runtime/*.java

    # == TRANSLATE SPECIFICATIONS
    print_step "translate specifications"

    java -Xss2m -ea -jar "$GENERATORS_DIR/StarSmith.jar" --spec "$config/kotlin.ls" --maxDepth 11 --allFeatures --toJava "$config/out/kotlin.java"

    javac -cp "$GENERATORS_DIR/StarSmith.jar":"$config/" -d "$config/out/classes" "$config/out/kotlin.java"
  fi
done

