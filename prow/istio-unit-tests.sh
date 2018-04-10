#!/bin/bash

# Copyright 2018 Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

WD=$(dirname $0)
WD=$(cd $WD; pwd)

# No unset vars, print commands as they're executed, and exit on any non-zero
# return code
set -u
set -x
set -e

# Artifact dir is hardcoded in Prow - boostrap to be in first repo checked out
ARTIFACTS_DIR="${GOPATH}/src/github.com/istio-releases/daily-release/_artifacts"

ISTIO_SHA=`curl $ISTIO_REL_URL/manifest.xml | grep -E "name=\"(([a-z]|-)*)/istio\"" | cut -f 6 -d \"`
[[ -z "${ISTIO_SHA}"  ]] && echo "error need to test with specific SHA" && exit 1

# Checkout istio at the greenbuild
mkdir -p ${GOPATH}/src/istio.io
pushd ${GOPATH}/src/istio.io
git clone -n https://github.com/istio/istio.git
pushd istio
git checkout $ISTIO_SHA

# Download envoy and go deps
make init

echo 'Running Unit Tests'

# Unit tests are run against a local apiserver and etcd.
# Integration/e2e tests in the other scripts are run against GKE or real clusters.
JUNIT_UNIT_TEST_XML="${ARTIFACTS_DIR}/junit_unit-tests.xml" \
T="-v" \
make build localTestEnv test

