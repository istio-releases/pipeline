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

BASE_DIR=$PWD

function cleanup() {
  # Mason cleanup
  mason_cleanup
  cat "${FILE_LOG}"
  cat "${PERF_LOG}"
}

source greenBuild.VERSION
# Exports $HUB, $TAG
echo "Using artifacts from HUB=${HUB} TAG=${TAG}"

# Check https://github.com/istio/test-infra/blob/master/boskos/configs.yaml
# for existing resources types
RESOURCE_TYPE="${RESOURCE_TYPE:-gke-perf-preset}"
OWNER='e2e-daily'
INFO_PATH="$(mktemp /tmp/XXXXX.boskos.info)"
FILE_LOG="$(mktemp /tmp/XXXXX.boskos.log)"

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

source "prow/mason_lib.sh"
source "prow/cluster_lib.sh"

trap cleanup EXIT

# use uploaded yaml artifacts rather than the ones generated locally
DAILY_BUILD=istio-$(echo ${ISTIO_REL_URL} | cut -d '/' -f 6)
LINUX_DIST_URL=${ISTIO_REL_URL}/${DAILY_BUILD}-linux.tar.gz
DEB_URL=${ISTIO_REL_URL}/deb
#disable ISTIO_REL_URL
unset ISTIO_REL_URL

echo core account is
gcloud config get-value core/account

wget -q $LINUX_DIST_URL
tar -xzf ${DAILY_BUILD}-linux.tar.gz
cp -R ${DAILY_BUILD}/install/* install/

wget -q https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz
tar -xvf helm-v2.9.1-linux-amd64.tar.gz
linux-amd64/helm template --set sidecarInjectorWebhook.enabled=false \
   --set global.proxy.image=proxy --namespace istio-system \
   --values install/kubernetes/helm/istio/values-istio-auth.yaml \
   install/kubernetes/helm/istio > install/kubernetes/istio-auth.yaml
cat  install/kubernetes/istio-auth.yaml



export ISTIOCTL="${GOPATH}/src/istio.io/istio/${DAILY_BUILD}/bin/istioctl"

get_resource "${RESOURCE_TYPE}" "${OWNER}" "${INFO_PATH}" "${FILE_LOG}"
setup_cluster

# istio-boskos-perf-03:
#   clusters:
#   - name: gke-041318-8zy1mr91wc
#     zone: us-central1-f
#   vms:
#   - name: gce-041318-lyiq9usadh
#     zone: us-central1-f
function export_perf_variables() {
  local PROJECT_INFO=$1
  export PROJECT=`     grep perf- $PROJECT_INFO      | cut -f 1 -d : `
  [[ -z "${PROJECT}"  ]] && echo "error could not parse project" && exit 11

  export CLUSTER_NAME=`grep  gke- $PROJECT_INFO      | cut -f 2 -d : | sed 's/ //g' `
  [[ -z "${CLUSTER_NAME}"  ]] && echo "error could not parse cluster name" && exit 12

  export VM_NAME=`     grep  gce- $PROJECT_INFO      | cut -f 2 -d : | sed 's/ //g' `
  [[ -z "${VM_NAME}"  ]] && echo "error could not parse vm name" && exit 13

  export ZONE=`        grep  zone $PROJECT_INFO -m 1 | cut -f 2 -d : | sed 's/ //g' `
  [[ -z "${VM_NAME}"  ]] && echo "error could not parse vm name" && exit 13

  export TOOLS_DIR="${PWD}/tools"

  ISTIOCTL=${ISTIOCTL:-bin/istioctl}
  export ISTIOCTL

  echo $PROJECT $CLUSTER_NAME $VM_NAME $ZONE $ISTIOCTL $TOOLS_DIR
}

unset IFS
export_perf_variables $INFO_PATH
QPS=-1
source "tools/setup_perf_cluster.sh"
update_gcp_opts
kubectl_setup

NAMESP_FILE="$(mktemp /tmp/XXXXX.namespace.yaml)"
cat > $NAMESP_FILE <<- EOM
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
EOM
kubectl create -f $NAMESP_FILE


function install_perf_and_test() {
  # setup VM
  update_gcp_opts
  setup_vm
  setup_vm_firewall
  update_fortio_on_vm
  run_fortio_on_vm

  # setup cluster
  kubectl_setup
  install_non_istio_svc
  setup_non_istio_ingress
  setup_istio_all

  get_ips
  VERSION="" # reset in case it changed
  TS="" # reset once per set
  QPS=-1
  run_4_tests
  QPS=400
  TS="" # reset once per set
  run_4_tests
}

PERF_LOG="$(mktemp /tmp/XXXXX.perf.log)" 
install_perf_and_test -s 2>&1 > $PERF_LOG

ls
gsutil -m cp qps* gs://fortio-data/daily.releases/data/
