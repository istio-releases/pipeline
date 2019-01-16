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


function set_pipeline_file() {
  # the top commit is the commit we need base our testing on
  # it is a merge commit in the following format
  # the short sha string 933ee0e is the sha of the actual commit
  #commit 524ee2b0ae1f4b68882472e862161e10a05ffecb
  #Merge: 174aef7 933ee0e
  #Author: ci-robot <ci-robot@k8s.io>
  #Date:   Thu Nov 29 02:02:24 2018 +0000
  #
  #    Merge commit '933ee0edfbc15629a5bb06d600c5fb52795be7c4' into krishna-test

  local commit
  commit=$(git log -n 1 | grep "^Merge" | cut -f 3 -d " ")
  local changed_files
  changed_files=($(git show --pretty="" --name-only $commit))

  export NUM_FILE_CHANGED=${#changed_files[@]}
  export PIPELINE_PARAM_FILE=
  export PARAM_FILE_CHANGED=false

  for changed_file in "${changed_files[@]}"
  do
    if [[ "${changed_file}" == *"/release_params.sh" ]]; then
      if [[ -z "$PIPELINE_PARAM_FILE" ]]; then
        export PARAM_FILE_CHANGED=true
        export PIPELINE_PARAM_FILE="${changed_file}"
      else
        echo more than one param files are changed: $changed_files
        exit 1
      fi
    fi
  done

  if [ "$PARAM_FILE_CHANGED" = false  ] ; then
    PIPELINE_PARAM_FILE="daily/release_params.sh"
  fi
}

set_pipeline_file
mkdir /workspace || true
cat "${PIPELINE_PARAM_FILE}" scripts/augmented_params.sh > /workspace/gcb_env.sh
source /workspace/gcb_env.sh

