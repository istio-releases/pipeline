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

# Exit immediately for non zero status
set -e

# Print commands
set -x

# sources the parameters file and sets build parameters env variables
source scripts/pipeline_parameters_lib.sh

export SHA=$(wget -q -O - "https://storage.googleapis.com/$CB_GCS_RELEASE_TOOLS_PATH/manifest.txt" | grep "tools" | cut -f 2 -d " ")

# Checkout istio/tools.git at corresponding SHA
mkdir -p ${GOPATH}/src/istio.io
pushd    ${GOPATH}/src/istio.io
  git clone -n https://github.com/$CB_GITHUB_ORG/tools.git
  pushd tools
    git checkout $SHA
  popd
popd
# Run the test script in istio/istio.
exec "$1"

