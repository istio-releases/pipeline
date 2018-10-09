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
# Check unset variables
set -u
# Print commands
set -x

# Helper functions
source "prow/utils.sh"
# import HUB, TAG, SHA, etc.
source "greenBuild.VERSION"

# Assert HUB and TAG are matching from all istioctl binaries.

download_untar_istio_release "${ISTIO_REL_URL}/docker.io" "${TAG}" docker.io
hub=$(docker.io/istio-${TAG}/bin/istioctl version | grep -oP 'Hub:"\K.*?(?=")')
tag=$(docker.io/istio-${TAG}/bin/istioctl version | grep -oP '{Version:"\K.*?(?=")')
[ "${hub}" == "docker.io/istio" ]
[ "${tag}" == "${TAG}" ]

download_untar_istio_release "${ISTIO_REL_URL}/gcr.io" "${TAG}" gcr.io
hub=$(gcr.io/istio-${TAG}/bin/istioctl version | grep -oP 'Hub:"\K.*?(?=")')
tag=$(gcr.io/istio-${TAG}/bin/istioctl version | grep -oP '{Version:"\K.*?(?=")')
[ "${hub}" == "gcr.io/istio-release" ]
[ "${tag}" == "${TAG}" ]

download_untar_istio_release "${ISTIO_REL_URL}" "${TAG}"
hub=$(istio-${TAG}/bin/istioctl version | grep -oP 'Hub:"\K.*?(?=")')
tag=$(istio-${TAG}/bin/istioctl version | grep -oP '{Version:"\K.*?(?=")')
[ "${hub}" == "${HUB}" ]
[ "${tag}" == "${TAG}" ]

