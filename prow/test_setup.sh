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

# Export $TAG, $HUB etc which are needed by the following functions.
source "greenBuild.VERSION"

# Artifact dir is hardcoded in Prow - boostrap to be in first repo checked out
export ARTIFACTS_DIR="${GOPATH}/src/github.com/istio-releases/daily-release/_artifacts"

# Get istio source code at the $SHA given by greenBuild.VERSION.
function git_clone_istio() {
  # Checkout istio at the greenbuild
  mkdir -p ${GOPATH}/src/istio.io
  pushd    ${GOPATH}/src/istio.io

  git clone -n https://github.com/istio/istio.git
  pushd istio

  #from now on we are in ${GOPATH}/src/istio.io/istio dir
  git checkout $SHA
}

# Set up e2e tests for release qualification
git_clone_istio

source "prow/lib.sh"

download_untar_istio_release ${ISTIO_REL_URL} ${TAG}

# Use downloaded yaml artifacts rather than the ones generated locally
cp -R istio-${TAG}/install/* install/

