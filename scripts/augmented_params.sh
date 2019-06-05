
# This following are appended to the actual param file.
export CB_CHECK_GREEN_SHA_AGE=${CB_CHECK_GREEN_SHA_AGE:-true}
export CB_GCS_BUILD_BUCKET=${CB_GCS_BUILD_BUCKET:-istio-release-pipeline-data}
export CB_GCS_STAGING_BUCKET=${CB_GCS_STAGING_BUCKET:-istio-prerelease}
export CB_GITHUB_ORG=${CB_GITHUB_ORG:-istio}
export CB_GITHUB_TOKEN_FILE_PATH=${CB_GITHUB_TOKEN_FILE_PATH=:-istio-secrets/github.txt.enc}

export CB_TEST_GITHUB_TOKEN_FILE_PATH=${CB_TEST_GITHUB_TOKEN_FILE_PATH:-}
export WORKFLOW=${WORKFLOW:-}

# config for specific type of pipeline (daily/monthly)
if [[ "$WORKFLOW" == "presubmit" ]]; then
  export CB_DOCKER_HUB="gcr.io/istio-release"
  export CB_ISTIOCTL_DOCKER_HUB="gcr.io/istio-release"
  export CB_PUSH_DOCKER_HUBS="gcr.io/istio-release"
  export CB_VERIFY_CONSISTENCY="false"
  export CB_GCS_BUILD_BUCKET="istio-presubmit-release-pipeline-data"
  export CB_GCS_STAGING_BUCKET="istio-presubmit-prerelease"

  export CB_GCS_MONTHLY_RELEASE_PATH=$CB_GCS_BUILD_BUCKET/monthly/$CB_VERSION
  export CB_GCS_BUILD_PATH=$CB_GCS_BUILD_BUCKET/$CB_PIPELINE_TYPE/$CB_VERSION
  export CB_GCS_FULL_STAGING_PATH=$CB_GCS_STAGING_BUCKET/$CB_PIPELINE_TYPE/$CB_VERSION
  export CB_GCS_RELEASE_TOOLS_PATH=$CB_GCS_BUILD_BUCKET/release-tools/$CB_PIPELINE_TYPE/$CB_VERSION

elif [[ "$CB_PIPELINE_TYPE" ==  "daily" ]]; then
  export CB_DOCKER_HUB=${CB_DOCKER_HUB:-gcr.io/istio-release}
  export CB_ISTIOCTL_DOCKER_HUB=${CB_ISTIOCTL_DOCKER_HUB:-gcr.io/istio-release}
  export CB_PUSH_DOCKER_HUBS=${CB_PUSH_DOCKER_HUBS:-gcr.io/istio-release}
  export CB_VERIFY_CONSISTENCY=${CB_VERIFY_CONSISTENCY:-false}

  export CB_GCS_MONTHLY_RELEASE_PATH=${CB_GCS_MONTHLY_RELEASE_PATH:-}
  export CB_GCS_BUILD_PATH=${CB_GCS_BUILD_PATH:-$CB_GCS_BUILD_BUCKET/daily-build/$CB_VERSION}
  export CB_GCS_FULL_STAGING_PATH=${CB_GCS_FULL_STAGING_PATH:-$CB_GCS_STAGING_BUCKET/daily-build/$CB_VERSION}
  export CB_GCS_RELEASE_TOOLS_PATH=${CB_GCS_RELEASE_TOOLS_PATH:-$CB_GCS_BUILD_BUCKET/release-tools/daily-build/$CB_VERSION}

elif [[ "$CB_PIPELINE_TYPE" ==  "monthly" ]]; then
  export CB_DOCKER_HUB=${CB_DOCKER_HUB:-docker.io/istio}
  export CB_ISTIOCTL_DOCKER_HUB=${CB_ISTIOCTL_DOCKER_HUB:-docker.io/istio}
  export CB_PUSH_DOCKER_HUBS=${CB_PUSH_DOCKER_HUBS:-docker.io/istio}
  export CB_VERIFY_CONSISTENCY=${CB_VERIFY_CONSISTENCY:-true}

  export CB_GCS_MONTHLY_RELEASE_PATH=${CB_GCS_MONTHLY_RELEASE_PATH:-istio-release/releases/$CB_VERSION}
  export CB_GCS_BUILD_PATH=${CB_GCS_BUILD_PATH:-$CB_GCS_BUILD_BUCKET/prerelease/$CB_VERSION}
  export CB_GCS_FULL_STAGING_PATH=${CB_GCS_FULL_STAGING_PATH:-$CB_GCS_STAGING_BUCKET/prerelease/$CB_VERSION}
  export CB_GCS_RELEASE_TOOLS_PATH=${CB_GCS_RELEASE_TOOLS_PATH:-$CB_GCS_BUILD_BUCKET/release-tools/prerelease/$CB_VERSION}

else
  error CB_PIPELINE_TYPE
fi
