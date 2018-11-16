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
#set -x

BASE_DIR=$PWD

# Artifact dir is hardcoded in Prow - boostrap to be in first repo checked out
ARTIFACTS_DIR="${GOPATH}/src/github.com/istio-releases/daily-release/_artifacts"

function cleanup() {
  pwd; ls
  cat qps*
  sleep 15m

  # Mason cleanup
  mason_cleanup
  cat "${FILE_LOG}"
}

function get_istio_code() {
  source "test/greenBuild.VERSION"
  # Exports $HUB, $TAG
  echo "Using artifacts from HUB=${HUB} TAG=${TAG}"

  # Check https://github.com/istio/test-infra/blob/master/boskos/configs.yaml
  # for existing resources types
  RESOURCE_TYPE="${RESOURCE_TYPE:-gke-perf-preset}"
  OWNER='e2e-daily'
  INFO_PATH="$(mktemp /tmp/XXXXX.boskos.info)"
  FILE_LOG="$(mktemp /tmp/XXXXX.boskos.log)"


  echo "Using release url: ${ISTIO_REL_URL}"
  ISTIO_SHA=`curl $ISTIO_REL_URL/manifest.xml | grep -E "name=\"(([a-z]|-)*)/istio\"" | cut -f 6 -d \"`
  [[ -z "${ISTIO_SHA}"  ]] && echo "error need to test with specific SHA" && exit 1

  # Checkout istio at the greenbuild
  mkdir -p ${GOPATH}/src/istio.io
  pushd ${GOPATH}/src/istio.io
  git clone https://github.com/istio/istio.git --depth 1
  pushd istio
# git checkout $ISTIO_SHA #KPTD

  # use uploaded yaml artifacts rather than the ones generated locally
  DAILY_BUILD=istio-$(echo ${ISTIO_REL_URL} | cut -d '/' -f 6)
  LINUX_DIST_URL=${ISTIO_REL_URL}/${DAILY_BUILD}-linux.tar.gz
  DEB_URL=${ISTIO_REL_URL}/deb
  #disable  ISTIO_REL_URL
  unset     ISTIO_REL_URL

  wget -q $LINUX_DIST_URL
  tar -xzf ${DAILY_BUILD}-linux.tar.gz
  cp    -R ${DAILY_BUILD}/install/* install/
  cp install/kubernetes/istio-demo-auth.yaml install/kubernetes/istio-auth.yaml
}

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

  unset TOOLS_DIR
  export ISTIOCTL="${GOPATH}/src/istio.io/istio/${DAILY_BUILD}/bin/istioctl"

  echo ###############################################
  echo $PROJECT $CLUSTER_NAME $VM_NAME $ZONE $ISTIOCTL
}

function wait_istio_up() {
  for namespace in $(kubectl get namespaces --no-headers -o name); do
    for name in $(kubectl get deployment -o name -n ${namespace}); do 
      kubectl -n ${namespace} rollout status ${name} -w;
    done
  done
}

function test_pods_up() {
  not_running=`kubectl get pods --all-namespaces --no-headers | grep -v ^kube-system | grep -v "Running" | wc -l`
  if [[ "${not_running}" != "0" ]]; then
     kubectl get pods --all-namespaces | grep -v ^kube-system
     exit 4
  fi
}

function daily_install_setup_perf() {
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
  echo VM_IP $VM_IP VM_URL $VM_URL
}

function daily_run_perf_test() {
  VERSION="" # reset in case it changed
  TS="" # reset once per set
  QPS=-1
  run_4_tests
  QPS=400
  TS="" # reset once per set
  run_4_tests
}

function daily_summarize() {
  gsutil -m cp qps* gs://fortio-data/daily.releases/data/
  echo
}

function create_istio_system_namespace() {
  NAMESP_FILE="$(mktemp /tmp/XXXXX.namespace.yaml)"
  cat > $NAMESP_FILE <<- EOM
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
EOM
  kubectl create -f $NAMESP_FILE || echo istio-system most likely created
}

get_istio_code
# directory now is istio root dir

source "prow/mason_lib.sh"
source "prow/cluster_lib.sh"
# get boskos/mason resource
get_resource "${RESOURCE_TYPE}" "${OWNER}" "${INFO_PATH}" "${FILE_LOG}"
setup_cluster # setup boskos cluster
trap cleanup EXIT


echo core account is
gcloud config get-value core/account

unset IFS
export_perf_variables $INFO_PATH
QPS=-1
source "tools/setup_perf_cluster.sh"
update_gcp_opts
kubectl_setup
create_istio_system_namespace

echo ======================================= set up perf env ================================================
daily_install_setup_perf
echo ======================================= run perf test ==================================================
daily_run_perf_test
echo ======================================= dailyperf test done ==========================================

test_pods_up
# summarize the information fail/pass, and copy if pass???
daily_summarize

