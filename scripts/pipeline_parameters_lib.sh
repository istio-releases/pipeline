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
  local num_files_changed
  num_files_changed=$(git show --pretty="" --name-only $commit | wc -l)
  local changed_file
  changed_file=$(git show --pretty="" --name-only $commit)

  # This job fails if not exactly one param file is updated in the PR.
  # For now it helps to gate unintended build/test/release because of prow
  # config caveat, when run_if_changed and run_after_success do not mix.
  # Therefore, updating any other release scripts will require manual merge
  # from  repo admins (i.e. release owners).
  #
  # Eventually, this should be fixed when prow implements proper workflow
  # support.
  if [[ "$num_files_changed" != "1" ]]; then
    echo more files changed than expected: $changed_file
    exit 1
  fi

  if [[ "${changed_file}" == *"/release_params.sh" ]]; then
    PIPELINE_PARAM_FILE="${changed_file}"
  else
    echo error parameters file did not change: $changed_file
    exit 33
  fi
}

set_pipeline_file
mkdir /workspace || true
cat "${PIPELINE_PARAM_FILE}" scripts/augmented_params.sh > /workspace/gcb_env.sh
source /workspace/gcb_env.sh

