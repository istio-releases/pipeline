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

# exports $HUB and $TAG
source greenBuild.VERSION
echo "Using artifacts from HUB=${HUB} TAG=${TAG} PROJECT=${PROJECT}"

ISTIOCTL_URL="https://storage.googleapis.com/${PROJECT}/builds/master/${TAG}"
echo "using ISTIOCTL_URL=${ISTIOCTL_URL}"

git clone https://github.com/istio/istio.git
cd istio
./tests/e2e.sh ${E2E_ARGS[@]:-} "$@" \
  --mixer_tag "${TAG}"\
  --mixer_hub "${HUB}"\
  --pilot_tag "${TAG}"\
  --pilot_hub "${HUB}"\
  --ca_tag "${TAG}"\
  --ca_hub "${HUB}"\
  --istioctl_url "${ISTIOCTL_URL}"
