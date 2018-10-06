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

function cleanup() {
  # log gathering
  cp -a /tmp/istio* ${ARTIFACTS_DIR}
  # Mason cleanup
  mason_cleanup
  cat "${FILE_LOG}"
}

# Helper functions
source "prow/utils.sh"
# Exports $HUB, $TAG, $SHA
source greenBuild.VERSION

echo "Using artifacts from HUB=${HUB} TAG=${TAG}"

# Check https://github.com/istio/test-infra/blob/master/boskos/configs.yaml
# for existing resources types
RESOURCE_TYPE="${RESOURCE_TYPE:-gke-e2e-test}"
OWNER='e2e-daily'
INFO_PATH="$(mktemp /tmp/XXXXX.boskos.info)"
FILE_LOG="$(mktemp /tmp/XXXXX.boskos.log)"

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

# Download envoy and go deps
make init

download_untar_istio_release ${ISTIO_REL_URL} ${TAG}

# Use downloaded yaml artifacts rather than the ones generated locally
cp -R istio-${TAG}/install/* install/

get_resource "${RESOURCE_TYPE}" "${OWNER}" "${INFO_PATH}" "${FILE_LOG}"
setup_cluster

echo 'Running E2E Tests'
# The --default_proxy flag overwrites both --proxy_hub  and --proxy_tag
E2E_ARGS=(
  --ca_hub="${HUB}"
  --ca_tag="${TAG}"
  --deb_url=${ISTIO_REL_URL}/deb
  --istioctl "${GOPATH}/src/istio.io/istio/istio-${TAG}/bin/istioctl"
  --mason_info="${INFO_PATH}"
  --mixer_hub="${HUB}"
  --mixer_tag="${TAG}"
  --pilot_hub="${HUB}"
  --pilot_tag="${TAG}"
  --proxy_hub="${HUB}"
  --proxy_tag="${PROXY_SKEW_TAG:-${TAG}}"
  --test_logs_path="${ARTIFACTS_DIR}"
)

E2E_TARGET=${E2E_TARGET:-e2e_all}
time E2E_ARGS="${E2E_ARGS[@]}" EXTRA_E2E_ARGS="$@" \
  JUNIT_E2E_XML="${ARTIFACTS_DIR}/junit_daily-release.xml" \
  make with_junit_report TARGET=${E2E_TARGET}
