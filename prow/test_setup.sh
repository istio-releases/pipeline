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


function set_pipeline_type() {
  # the top commit is the commit we need base our testing on
  # it is a merge commit in the following format
  # the short sha string 933ee0e is the sha of the actual commit
  #commit 524ee2b0ae1f4b68882472e862161e10a05ffecb
  #Merge: 174aef7 933ee0e
  #Author: ci-robot <ci-robot@k8s.io>
  #Date:   Thu Nov 29 02:02:24 2018 +0000
  #
  #    Merge commit '933ee0edfbc15629a5bb06d600c5fb52795be7c4' into krishna-test

  commit=$(git log -n 1 | grep "^Merge" | cut -f 3 -d " ")
  changed_files=$(git show --pretty="" --name-only $commit)

  # The files in path daily/test or monthly/test determines the pipeline type
  if [[ "${changed_files}" == *"daily/test/"* ]]; then
    echo matched daily
    PIPELINE_TYPE=daily
  fi

  if [[ "${changed_files}" == *"monthly/test/"* ]]; then
    echo matched monthly
    if [[ -n "${PIPELINE_TYPE}" ]]; then
      echo error already matched ${PIPELINE_TYPE}
      exit 1
    fi
   PIPELINE_TYPE=monthly
  fi

  if [[ -z "${PIPELINE_TYPE}" ]]; then
    echo $changed_files
    echo Error cant find pipeline type
    exit 2
  fi
}

set_pipeline_type
source "$PIPELINE_TYPE/test/build_parameters.sh"

export SHA=$(wget -q -O - "https://storage.googleapis.com/$CB_GCS_RELEASE_TOOLS_PATH/manifest.txt" | grep "istio" | cut -f 2 -d " ")
export HUB="$CB_DOCKER_HUB"
export TAG="$CB_VERSION"
export ISTIO_REL_URL="https://storage.googleapis.com/$CB_GCS_BUILD_PATH"

# Artifact dir is hardcoded in Prow - boostrap to be in first repo checked out
export ARTIFACTS_DIR="${GOPATH}/src/github.com/istio-releases/daily-release/_artifacts"

# Get istio source code at the $SHA for this build
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
