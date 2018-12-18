# Introduction

This repository is used to kick off new Istio releases. Updating a parameter file
and sending out a git pull request triggers release automation to build release
artifacts, run release qualification tests, and if all required tests have passed,
publish the release artifacts to the final release destination.

# Kick off a Manual Daily Release

The one time setup is to clone this repository in your git environment.
```shell
git clone https://github.com/istio-releases/pipeline.git
cd pipeline
```

And then you can kick off a new daily release using the following command. 
```shell
GIT_BRANCH={branch} ./scripts/trigger_daily_release.sh
```

You must provide the release branch where you want to build the release from.
The script automatically determines the latest branch SHA and the release
version using the branch name and timestamp, and generates a new pull request
in the requested branch to trigger release automation. The PR URL can be found
at the end of script output.

Example:
```shell
2018/12/18 12:00:48 Creating a PR with Title: "DAILY master-20181218-12-00" for repo pipeline
2018/12/18 12:00:49 Created new PR at https://github.com/istio-releases/pipeline/pull/109
```

The generated pull request will be merged automatically when all required tests have
passed. In case some required tests have failed, they will be retried automatically up to
3 times. And the PR will be closed if it cannot be merged for a day.

# Understanding Release Pull Request

A release pull request first triggers a prow job named "prow/release-build", which builds
request artifacts and made them available for testing. This step also builds all docker
images, and have them pushed to a public registry.

Once "prow/release-build" completes, the test jobs are started. This is the release qualification
step which consumes the release artifacts and make sure they are up to a certain standard, including:
* istio/istio unit and integration tests
* istio/istio E2E tests (using the release images)
* istioctl tests
* upgrade/downupgrade tests

You can monitor both the build and test status and log in the PR. In particular, you
can find the build log in the "prow/release-build" log.

<img src="https://github.com/hklai/istio/blob/istio_wiki/wiki/release_pr.png?raw=true" alt="example" width="600"/>

Once all tests have passed, the pull request will be merged automatically. A post-submit job
will do all the heavy lifting of publishing release artifacts to the right place. You can find the
post-submit job at http://prow.istio.io/?repo=istio-releases%2Fpipeline&type=postsubmit.

# Kick off a Monthly Release

Similar to daily releases, a monthly (or LTS /patch) release can be kicked off by running the
trigger command.

```shell
GIT_BRANCH={branch} PIPELINE_TYPE=monthly VERSION={version} COMMIT={sha} ./scripts/trigger_daily_release.sh
```

Unlike daily releases, you must specify ```PIPELINE_TYPE=monthly``` with the expected version string
(e.g. 1.0.5), the release branch name (e.g. release-1.0), and the SHA from the branch where the release
should be cut from.

Alterhatively, one can directly update monthly/release_parameters.sh and send a pull request to the
branch where the release is cut from. That way, you can even configure some advanced release parameters
if you know what you are doing. Example: https://github.com/istio-releases/pipeline/pull/102/files

# Release Artifact Locations
## Daily Releases
* Tarballs: https://gcsweb.istio.io/gcs/istio-prerelease/daily-build/
* Images: gcr.io/istio-release

## Monthly/LTS/Patch Releases
* Tarballs: https://github.com/istio/istio/releases
* Images: docker.io/istio


# Scheduled Jobs

Daily releases are simply scheduled jobs that invokes ```./scripts/trigger_daily_release.sh``` daily. 
These jobs can be found at:
* master: https://prow.istio.io/?type=periodic&job=release-trigger-daily-build-master
* release-1.1: http://prow.istio.io/?type=periodic&job=release-trigger-daily-build-release-1.0
* release-1.0: http://prow.istio.io/?type=periodic&job=release-trigger-daily-build-release-1.1

There is also a janitor job that runs every 30 minutes. It goes through all the open release pull
requests in istio-releases/pipeline, merges the requests that have all tests passed, closes the
requests that have expired, and triggers retest in case a test fails. The job can be found at
http://prow.istio.io/?type=periodic&job=release-requests-janitor

