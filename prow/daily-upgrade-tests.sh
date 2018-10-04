#!/bin/bash

# Copyright 2017 Istio Authors

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
# Check unset variables
set -u
# Print commands
set -x

export SOURCE_VERSION=1.0.0

function cleanup() {
  # Mason cleanup
  mason_cleanup
  cat "${FILE_LOG}"
}

function download_untar_istio_linux_target_release_tar() {
  # Download artifacts
  LINUX_DIST_URL=${ISTIO_REL_URL}/${DAILY_BUILD}-linux.tar.gz
  EXPECTED_HUB=${EXPECTED_HUB:-"Hub: gcr.io/istio-release"}

  wget  -q "${LINUX_DIST_URL}"
  tar -xzf "${DAILY_BUILD}-linux.tar.gz"
}

function download_untar_istio_linux_source_release_tar() {
  # Download artifacts
  LINUX_DIST_URL="https://github.com/istio/istio/releases/download/${SOURCE_VERSION}/istio-${SOURCE_VERSION}-linux.tar.gz"

  wget  -q "${LINUX_DIST_URL}"
  tar -xzf "${SOURCE_RELEASE_BUILD}-linux.tar.gz"
}

# Exports $HUB, $TAG, $SHA
source greenBuild.VERSION
echo "Testing Upgrade from ${HUB}/${SOURCE_VERSION} to ${HUB}/
}"

# Check https://github.com/istio/test-infra/blob/master/boskos/configs.yaml
# for existing resources types
RESOURCE_TYPE="${RESOURCE_TYPE:-gke-e2e-test}"
OWNER='e2e-daily'
INFO_PATH="$(mktemp /tmp/XXXXX.boskos.info)"
FILE_LOG="$(mktemp /tmp/XXXXX.boskos.log)"

export DAILY_BUILD=istio-$(echo ${ISTIO_REL_URL} | cut -d '/' -f 6)

# Checkout istio at the greenbuild
mkdir -p ${GOPATH}/src/istio.io
pushd    ${GOPATH}/src/istio.io
git clone -n https://github.com/istio/istio.git

pushd istio
#from now on we are in ${GOPATH}/src/istio.io/istio dir

git checkout $SHA

source "prow/mason_lib.sh"
source "prow/cluster_lib.sh"
trap cleanup EXIT

export SOURCE_RELEASE_BUILD=istio-${SOURCE_VERSION}
download_untar_istio_linux_source_release_tar
download_untar_istio_linux_target_release_tar

get_resource "${RESOURCE_TYPE}" "${OWNER}" "${INFO_PATH}" "${FILE_LOG}"
setup_cluster

# Install fortio which is needed by the upgrade test.
go get fortio.org/fortio

./tests/upgrade/test_crossgrade.sh --from_hub=${HUB} --from_tag=${SOURCE_VERSION} --from_path=${SOURCE_RELEASE_BUILD} --to_hub=${HUB} --to_tag=${TAG} --to_path=${DAILY_BUILD}

