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

script_to_run="$1"
mkdir -p /workspace/go/src/istio.io/

if [[ "${SKIP_SOURCE_PIPELINE_PARAM}" == "true" ]]; then
  CB_BRANCH=$GIT_BRANCH
  CHECKOUT_SHA=""
  ISTIO_ORG=istio
else
  # sources the parameters file and sets build parameters env variables
  source rel_scripts/pipeline_parameters_lib.sh
  CHECKOUT_SHA=$CB_COMMIT
  ISTIO_ORG=$CB_GITHUB_ORG
fi

cd /workspace/go/src/istio.io/
git clone "https://github.com/$ISTIO_ORG/istio" -b $CB_BRANCH
cd istio
git checkout $CHECKOUT_SHA

# Check unset variables
set -u

cp release/gcb/*sh /workspace
exec release/gcb/$script_to_run
