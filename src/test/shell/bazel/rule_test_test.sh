#!/bin/bash
#
# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Test rule_test usage.
#

set -euo pipefail
# --- begin runfiles.bash initialization ---
if [[ ! -d "${RUNFILES_DIR:-/dev/null}" && ! -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  if [[ -f "$0.runfiles_manifest" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
  elif [[ -f "$0.runfiles/MANIFEST" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles/MANIFEST"
  elif [[ -f "$0.runfiles/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
    export RUNFILES_DIR="$0.runfiles"
  fi
fi
if [[ -f "${RUNFILES_DIR:-/dev/null}/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
  source "${RUNFILES_DIR}/bazel_tools/tools/bash/runfiles/runfiles.bash"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  source "$(grep -m1 "^bazel_tools/tools/bash/runfiles/runfiles.bash " \
            "$RUNFILES_MANIFEST_FILE" | cut -d ' ' -f 2-)"
else
  echo >&2 "ERROR: cannot find @bazel_tools//tools/bash/runfiles:runfiles.bash"
  exit 1
fi
# --- end runfiles.bash initialization ---

source "$(rlocation "io_bazel/src/test/shell/integration_test_setup.sh")" \
  || { echo "integration_test_setup.sh not found!" >&2; exit 1; }

function set_up() {
  export MSYS_NO_PATHCONV=1
  export MSYS2_ARG_CONV_EXCL="*"
}

function test_local_rule_test_in_root() {
  create_new_workspace
  cat > BUILD <<EOF
genrule(
    name = "turtle",
    outs = ["tmnt"],
    cmd = "echo 'Leonardo' > \$@",
    visibility = ["//visibility:public"],
)

load(
    "@bazel_tools//tools/build_rules:test_rules.bzl",
    "rule_test",
)

rule_test(
    name="turtle_rule_test",
    rule="//:turtle",
    generates=[
        "tmnt",
    ],
)
EOF

  bazel build //:turtle_rule_test &> $TEST_log || fail "turtle_rule_test failed"
}

function test_local_rule_test_in_subpackage() {
  create_new_workspace
  mkdir p
  cat > p/BUILD <<EOF
genrule(
    name = "turtle",
    outs = ["tmnt"],
    cmd = "echo 'Leonardo' > \$@",
    visibility = ["//visibility:public"],
)

load(
    "@bazel_tools//tools/build_rules:test_rules.bzl",
    "rule_test",
)

rule_test(
    name="turtle_rule_test",
    rule="//p:turtle",
    generates=[
        "tmnt",
    ],
)
EOF

  bazel build //p:turtle_rule_test &> $TEST_log || fail "turtle_rule_test failed"
}

function test_repository_rule_test_in_root() {
  create_new_workspace
  mkdir -p r

  cat >> WORKSPACE <<EOF
local_repository(name = "r", path = "r")
EOF
  cat > r/WORKSPACE <<EOF
workspace(name = "r")
EOF
  cat > r/BUILD <<EOF
genrule(
    name = "turtle",
    outs = ["tmnt"],
    cmd = "echo 'Leonardo' > \$@",
    visibility = ["//visibility:public"],
)
EOF
  cat > BUILD <<EOF
load(
    "@bazel_tools//tools/build_rules:test_rules.bzl",
    "rule_test",
)

rule_test(
    name="turtle_rule_test",
    rule="@r//:turtle",
    generates=[
        "tmnt",
    ],
)
EOF

  bazel build //:turtle_rule_test &> $TEST_log || fail "turtle_rule_test failed"
}

function test_repository_rule_test_in_subpackage() {
  create_new_workspace
  mkdir -p r

  cat >> WORKSPACE <<EOF
local_repository(name = "r", path = "r")
EOF
  cat > r/WORKSPACE <<EOF
workspace(name = "r")
EOF
  mkdir r/p
  cat > r/p/BUILD <<EOF
genrule(
    name = "turtle",
    outs = ["tmnt"],
    cmd = "echo 'Leonardo' > \$@",
    visibility = ["//visibility:public"],
)
EOF
  cat > BUILD <<EOF
load(
    "@bazel_tools//tools/build_rules:test_rules.bzl",
    "rule_test",
)

rule_test(
    name="turtle_rule_test",
    rule="@r//p:turtle",
    generates=[
        "tmnt",
    ],
)
EOF

  bazel build //:turtle_rule_test &> $TEST_log || fail "turtle_rule_test failed"
}

run_suite "rule_test tests"
