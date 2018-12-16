#!/bin/bash

# Copyright 2018 Istio Authors

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

set -x

GOPATH=${GOPATH:-$PWD/go}
mkdir -p {$GOPATH}/bin

time go get  istio.io/test-infra/toolbox/githubctl

if [[ ! -z "${RELEASE_BOT}" ]]; then
  git config --global user.name "TestRunnerBot"
  git config --global user.email "testrunner@istio.io"
fi

"$GOPATH/bin/githubctl" \
    --token_file="$GITHUB_TOKEN_FILE" \
    --op=cleanupReleaseRequests \
    --owner="istio-releases" \
    --repo="pipeline"

echo Build Triggered
