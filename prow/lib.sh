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

function download_untar_istio_assert_istioctl_version() {
	local url=$1
	local expected_hub=$2
	wget -q ${url}
	tar -xzf ${DAILY_BUILD}-linux.tar.gz

	local ISTIOCTL_BIN="${DAILY_BUILD}/bin/istioctl"
	local ISTIOCTL_HUB=$(${ISTIOCTL_BIN} version | grep Hub)
	# Assert hub from `istioctl version` points to ${expected_hub}
	[ "${ISTIOCTL_HUB}" == "${expected_hub}" ]
}
