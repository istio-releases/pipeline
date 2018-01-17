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


#######################################
# Presubmit script triggered by Prow. #
#######################################

# Exit immediately for non zero status
set -e
# Check unset variables
set -u
# Print commands
set -x

export KUBECONFIG=${HOME}/.kube/config
if [[ ${CI:-} == 'bootstrap' ]]; then
  export KUBECONFIG=/home/bootstrap/.kube/config
fi

# Exports $HUB, $TAG, and $ISTIOCTL_URL
source greenBuild.VERSION
echo "Using artifacts from HUB=${HUB} TAG=${TAG} ISTIOCTL_URL=${ISTIOCTL_URL}"

# Checkout istio at the greenbuild
mkdir -p ${GOPATH}/src/istio.io
cd ${GOPATH}/src/istio.io
git clone -n https://github.com/istio/istio.git
cd istio
ISTIO_SHA=`curl $ISTIOCTL_URL/../manifest.xml | grep istio/istio | cut -f 6 -d \"`
[[ -z "${ISTIO_SHA}"  ]] && echo "error need to test with specific SHA" && exit 1
git checkout $ISTIO_SHA

# Download envoy and go deps
make init

# log gathering
mkdir -p ${GOPATH}/src/istio.io/istio/_artifacts
trap "cp -a /tmp/istio* ${GOPATH}/src/istio.io/istio/_artifacts" EXIT

# use uploaded yaml artifacts rather than the ones generated locally
DAILY_BUILD=istio-$(echo ${ISTIOCTL_URL} | cut -d '/' -f 6)
LINUX_DIST_URL=${ISTIOCTL_URL/istioctl/${DAILY_BUILD}-linux.tar.gz}
wget $LINUX_DIST_URL
tar -xzf ${DAILY_BUILD}-linux.tar.gz
cp -R ${DAILY_BUILD}/install/* install/

echo 'Running Integration Tests'
make e2e_all E2E_ARGS="--istioctl_url "${ISTIOCTL_URL}" "$@""
