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

set -x

# /workspace is the working directory for the scripts
mkdir /workspace
cp "release/build_env.sh" "/workspace/gcb_env.sh"
source "/workspace/gcb_env.sh"


cd /workspace

#copy files over to final destination
gsutil -m cp -r "gs://$CB_GCS_BUILD_PATH" "gs://$CB_GCS_FULL_STAGING_PATH"

if [[ "$CB_PIPELINE_TYPE" ==  "daily" ]]; then

  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/rel_push_docker.sh" .
  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/rel_push_docker_daily.sh" .
  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/rel_daily_complete.sh" .
  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/docker_tag_push_lib.sh" .
  ./rel_push_docker_daily.sh
  ./rel_daily_complete.sh

elif [[ "$CB_PIPELINE_TYPE" ==  "monthly" ]]; then

  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/github_publish_release.sh" .
  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/github_tag_release.sh" .
  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/gcb_lib.sh" .
  gsutil -qm cp -P "gs://$CB_GCS_RELEASE_TOOLS_PATH/json_parse_shared.sh" .

  ./github_publish_release.sh
  ./github_tag_release.sh

else
  error CB_PIPELINE_TYPE
fi
