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

function usage() {
    echo "error $1 is wrong"
    exit 1
}

# CB_COMMIT is used only to override green build and build at specific sha
#export CB_COMMIT=
# CB_TEST_GITHUB_TOKEN_FILE_PATH is used only to for testing purposes
#export CB_TEST_GITHUB_TOKEN_FILE_PATH=

function check_minimum_config_needed() {
  # minimum config needed
  [[ -z "$CB_BRANCH" ]] && usage "CB_BRANCH"
  [[ -z "$CB_PIPELINE_TYPE" ]] && usage "CB_PIPELINE_TYPE"
  [[ -z "$CB_VERSION" ]] && usage "CB_VERSION"
}


function set_common_config() {
# common config for daily and monthly pipelines

if [[ -z "$CB_CHECK_GREEN_SHA_AGE" ]]; then
    export CB_CHECK_GREEN_SHA_AGE=true
fi
if [[ -z "$CB_GCS_BUILD_BUCKET" ]]; then
    export CB_GCS_BUILD_BUCKET=istio-release-pipeline-data
fi
if [[ -z "$CB_GCS_STAGING_BUCKET" ]]; then
    export CB_GCS_STAGING_BUCKET=istio-prerelease
fi
if [[ -z "$CB_GITHUB_ORG" ]]; then
    export CB_GITHUB_ORG=istio
fi
if [[ -z "$CB_GITHUB_TOKEN_FILE_PATH" ]]; then
    #export CB_GITHUB_TOKEN_FILE_PATH=/etc/github
    export CB_GITHUB_TOKEN_FILE_PATH=istio-secrets/github.txt.enc
fi
}


function set_daily_config() {
  if [[ -z "$CB_DOCKER_HUB" ]]; then
      export CB_DOCKER_HUB=gcr.io/istio-release
  fi
  if [[ -z "$CB_ISTIOCTL_DOCKER_HUB" ]]; then
      export CB_ISTIOCTL_DOCKER_HUB=gcr.io/istio-release
  fi
  if [[ -z "$CB_PUSH_DOCKER_HUBS" ]]; then
      export CB_PUSH_DOCKER_HUBS=gcr.io/istio-release
  fi
  if [[ -z "$CB_VERIFY_CONSISTENCY" ]]; then
      export CB_VERIFY_CONSISTENCY=false
  fi

# derivative config
if [[ -z "$CB_GCS_BUILD_PATH" ]]; then
    export CB_GCS_BUILD_PATH="$CB_GCS_BUILD_BUCKET/daily-build/$CB_VERSION"
fi
if [[ -z "$CB_GCS_FULL_STAGING_PATH" ]]; then
    export CB_GCS_FULL_STAGING_PATH="$CB_GCS_STAGING_BUCKET/daily-build/$CB_VERSION"
fi
if [[ -z "$CB_GCS_RELEASE_TOOLS_PATH" ]]; then
    export CB_GCS_RELEASE_TOOLS_PATH="$CB_GCS_BUILD_BUCKET/release-tools/daily-build/$CB_VERSION"
fi
}


function set_monthly_config() {
  if [[ -z "$CB_DOCKER_HUB" ]]; then
      export CB_DOCKER_HUB=docker.io/istio
  fi
  if [[ -z "$CB_ISTIOCTL_DOCKER_HUB" ]]; then
      export CB_ISTIOCTL_DOCKER_HUB=docker.io/istio
  fi
  if [[ -z "$CB_PUSH_DOCKER_HUBS" ]]; then
      export CB_PUSH_DOCKER_HUBS=docker.io/istio
  fi
  if [[ -z "$CB_VERIFY_CONSISTENCY" ]]; then
      export CB_VERIFY_CONSISTENCY=true
  fi
  if [[ -z "$CB_GCS_MONTHLY_RELEASE_PATH" ]]; then
      export CB_GCS_MONTHLY_RELEASE_PATH=istio-release/releases/$CB_VERSION
  fi

# derivative config
if [[ -z "$CB_GCS_BUILD_PATH" ]]; then
    export CB_GCS_BUILD_PATH="$CB_GCS_BUILD_BUCKET/prerelease/$CB_VERSION"
fi
if [[ -z "$CB_GCS_FULL_STAGING_PATH" ]]; then
    export CB_GCS_FULL_STAGING_PATH="$CB_GCS_STAGING_BUCKET/prerelease/$CB_VERSION"
fi
if [[ -z "$CB_GCS_RELEASE_TOOLS_PATH" ]]; then
    export CB_GCS_RELEASE_TOOLS_PATH="$CB_GCS_BUILD_BUCKET/release-tools/prerelease/$CB_VERSION"
fi
}

function export_var_to_build_env_file() {
  local exportvar=(
  CB_BRANCH
  CB_CHECK_GREEN_SHA_AGE
  CB_COMMIT
  CB_DOCKER_HUB
  CB_GCS_BUILD_BUCKET
  CB_GCS_BUILD_PATH
  CB_GCS_FULL_STAGING_PATH
  CB_GCS_MONTHLY_RELEASE_PATH
  CB_GCS_RELEASE_TOOLS_PATH
  CB_GCS_STAGING_BUCKET
  CB_GITHUB_ORG
  CB_GITHUB_TOKEN_FILE_PATH
  CB_ISTIOCTL_DOCKER_HUB
  CB_PIPELINE_TYPE
  CB_PUSH_DOCKER_HUBS
  CB_TEST_GITHUB_TOKEN_FILE_PATH
  CB_VERIFY_CONSISTENCY
  CB_VERSION
  )

  {
    echo "# This script holds parameters specific to an instance of a build"
    for var in "${exportvar[@]}"
    do
    echo "export $var=${!var}"
    done
  } > "build/build_env.sh"
}


check_minimum_config_needed
set_common_config
# config for specific type of pipeline (daily/monthly)
if [[ "$CB_PIPELINE_TYPE" ==  "daily" ]]; then
  set_daily_config
elif [[ "$CB_PIPELINE_TYPE" ==  "monthly" ]]; then
  set_monthly_config
else
  error CB_PIPELINE_TYPE
fi

export_var_to_build_env_file
