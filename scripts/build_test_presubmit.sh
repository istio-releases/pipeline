#!/bin/bash

# Copyright 2019 Istio Authors

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Exit immediately for non zero status
set -e

# Print commands
set -x

# sources the parameters file and sets build parameters env variables
source scripts/pipeline_parameters_lib.sh

export WORKFLOW="presubmit"
IFS="/" read -ra TEST_FILE <<< $@
test_name=${TEST_FILE[1]%.*}

export CB_VERSION=$(echo "$CB_VERSION"-"${test_name//e2e-/}" | md5sum | awk '{print $1}'s)


sed -i -- 's/export WORKFLOW=.*/export WORKFLOW=presubmit/g' /workspace/gcb_env.sh
sed -i -- "s/export CB_VERSION=.*/export CB_VERSION=${CB_VERSION}/g" /workspace/gcb_env.sh

source /workspace/gcb_env.sh
export HUB="$CB_DOCKER_HUB"
export TAG="$CB_VERSION"

function build_istio_release_image() {
	mkdir -p /workspace/go/src/istio.io/
	cd /workspace/go/src/istio.io/
	git clone "https://github.com/$CB_GITHUB_ORG/istio" -b $CB_BRANCH
	cd istio
	git checkout $CB_COMMIT
	cp release/gcb/*sh /workspace
	. ./release/gcb/run_build.sh
}

# Get istio source code at the $SHA for this build
function git_clone_istio() 
{  
  echo Starting git_clone_istio
  # Checkout istio at the greenbuild
  mkdir -p ${GOPATH}/src/istio.io
  pushd    ${GOPATH}/src/istio.io

  git clone -n https://github.com/$CB_GITHUB_ORG/istio.git
  pushd istio

  #from now on we are in ${GOPATH}/src/istio.io/istio dir
  git checkout $SHA
}

# if [ "$PARAM_FILE_CHANGED" = true ] ; then
  # build_istio_release_image
# fi

build_istio_release_image

export SHA=$(wget -q -O - "https://storage.googleapis.com/$CB_GCS_RELEASE_TOOLS_PATH/manifest.txt" | grep "istio" | cut -f 2 -d " ")
export ISTIO_REL_URL="https://storage.googleapis.com/$CB_GCS_BUILD_PATH"
# Set up e2e tests for release qualification
git_clone_istio

source "prow/lib.sh"

download_untar_istio_release ${ISTIO_REL_URL} ${TAG}

# Use downloaded yaml artifacts rather than the ones generated locally
cp -R istio-${TAG}/install/* install/

rm -rf /root/.docker
export DOCKER_CONFIG=""
# Run the test script in istio/istio.
exec "$@"