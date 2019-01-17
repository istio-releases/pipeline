# Introduction

This repository is used to kick off new Istio releases. Updating a parameter file
and sending out a git pull request triggers release automation to build release
artifacts, run release qualification tests, and if all required tests have passed,
publish the release artifacts to the final release destination.

# Starting a New Release

## One Time Setup
Fork and clone this repository in your github environnment. You will start a new
release by sending out a pull request.

## Trigger a New Daily Release
You can kick off a new daily release by running the following command. 
```shell
GIT_BRANCH={branch} ./scripts/trigger_daily_release.sh
```

You must provide the istio release branch where you want to build the release from.

The script automatically determines the latest branch SHA and the release
version using the branch name and timestamp, checks out the same branch in this repo
(this repository has the same set of release branchhes found in istio/istio), and
updates [daily/release_params.sh](https://github.com/istio-releases/pipeline/blob/master/daily/release_params.sh).

All you need to do is to send a new pull request containing the updated parameter
file to trigger a kick off a new daily release. As a convention, please use
`DAILY <release version>` as the PR title.

## Understanding Release Pull Request

A release pull request first triggers a prow job named "prow/release-build", which builds
request artifacts and make them available for testing. This step also builds docker images,
and have them pushed to a public registry.

Once "prow/release-build" completes, the test jobs are started. This is the release qualification
step which consumes the release artifacts and make sure they are up to a certain standard, including:
* istio/istio unit and integration tests
* istio/istio E2E tests (using the release images)
* istioctl tests
* upgrade/downupgrade tests

You can monitor both the build and test status and log in the PR. In particular, you
can find the build log in the "prow/release-build" log.

<img src="https://github.com/hklai/istio/blob/istio_wiki/wiki/release_pr.png?raw=true" alt="example" width="600"/>

Test failures will be retried up to three times. Once all tests have passed, the pull request will
be merged *automatically*. A post-submit job will do all the heavy lifting of publishing release
artifacts to the right place. You can find the post-submit job at 
http://prow.istio.io/?repo=istio-releases%2Fpipeline&type=postsubmit.


## Kick off a Monthly Release

Similar to daily releases, a monthly (or LTS/patch) release can be kicked off by sending out
a new pull request. As the monthly release parameters are typically determined manually, you
can first check out the right release branch (e.g. release-1.1), and modify the parameters
directly in [monthly/release_params.sh](https://github.com/istio-releases/pipeline/blob/master/monthly/release_params.sh).

```shell
export CB_BRANCH=master
export CB_COMMIT=f927d1ec433cecc6f66fcdcc0af38327b70efa68
export CB_PIPELINE_TYPE=monthly
export CB_VERSION=1.2.0-snapshot.0
```

* ```CB_BRANCH``` is the release branch in [istio/istio](https://www.github.com/istio/istio)
where you want to build from. You **must** modify ```release_params.sh``` in the corresponding
branch. (i.e. if you are building a monthly from istio [release-1.1](https://github.com/istio/istio/tree/release-1.1), you must update  ```release_params.sh``` in the [release-1.1](https://github.com/istio-releases/pipeline/tree/release-1.1) of this repo.

* ```CB_COMMIT``` is the commit SHA in the [istio/istio](https://www.github.com/istio/istio)
release branch where you want to build the release from.

* ```CB_PIPELINE_TYPE``` is the release type. It should be ```monthly``` for monthly releases
and you can leave the existing value alone.

* ```CB_VERSION``` is the new release version. E.g. 1.0.6 or 1.1.0-snapshot.5.

You can even configure some advanced release parameters if you know what you are doing. 
Example: https://github.com/istio-releases/pipeline/pull/102/files

And then you can send a PR with this file change to trigger release automation.  As a convention,
please use `MONTHLY <release version>` as the PR title.


# Monitoring

You can find all the pull requests in https://github.com/istio-releases/pipeline/pulls.
And you can find the build and test log in the presubmit jobs of these pull requests.

All presubmit and postsubmit jobs that run in this repository can be found at 
https://prow.istio.io/?repo=istio-releases%2Fpipeline


# Maintenance Notes

## Maintainer Setup
As a maintainer, make sure you have write permission on this repositroy. Then, set an environment
variable ```GITHUB_TOKEN_FILE``` point to a local file that contains your github token (create one
at https://github.com/settings/tokens if you do not have any).

With this, running ```scripts/trigger_daily_release.sh``` will create a temporary branch and a
pull request for you automatically. 

## Branch Structure
This repositoy must have the same release branches (i.e. master, release-x.y) found in istio/istio.

## Prow Config
Build, test, and release job config can be found at 
https://github.com/istio/test-infra/tree/master/prow/cluster/jobs/istio-releases/pipeline.
Each branch has its own configuration. If you want to add a new release test, this is
where you should look.

The scheduled jobs config can be found at
https://github.com/istio/test-infra/blob/master/prow/cluster/jobs/all-periodics.yaml

## Release Scripts
This repository has some wrapper scripts in https://github.com/istio-releases/pipeline/tree/master/scripts,
but the actual build, test, and release scripts are in istio/istio.

build/release: https://github.com/istio/istio/tree/master/release
test: https://github.com/istio/istio/tree/master/prow

## Why is GCB/CB prefix everywhere?
Legacy! Releases were built by GCB (Google Clound Builder) before, and these prefixes had not been
cleaned up.

## Scheduled Jobs
Daily releases are simply scheduled jobs that invokes ```./scripts/trigger_daily_release.sh``` daily. 
These jobs can be found at:
* master: https://prow.istio.io/?type=periodic&job=release-trigger-daily-build-master
* release-1.1: http://prow.istio.io/?type=periodic&job=release-trigger-daily-build-release-1.0
* release-1.0: http://prow.istio.io/?type=periodic&job=release-trigger-daily-build-release-1.1

There is also a janitor job that runs every 30 minutes. It goes through all the open release pull
requests in istio-releases/pipeline, merges the requests that have all tests passed, closes the
requests that have expired, and triggers retest in case a test fails. The job can be found at
http://prow.istio.io/?type=periodic&job=release-requests-janitor

## Adding a New Release Branch
1. Add the new release branch (e.g. release-1.2) in istio/istio, istio/api, istio/proxy, and istio/cni.
1. Add the same release branch in this repo (i.e. https://github.com/istio-releases/pipeline) from master,
and update the param files (e.g. https://github.com/istio-releases/pipeline/blob/master/daily/release_params.sh)
with the new branch name.
1. Create a new Prow config for the new branch, by cloning 
https://github.com/istio/test-infra/blob/master/prow/cluster/jobs/istio-releases/pipeline/istio-releases.pipeline.master.yaml 
to istio-releases.pipeline.release-x.y.yaml, and update the branch name in it.

## Addomg a New Release Test Job
Find the prow config for the branch you want to add a new job in 
https://github.com/istio/test-infra/tree/master/prow/cluster/jobs/istio-releases/pipeline, and add/update the job
config there.

## Daily Release Artifacts Location
* Tarballs: https://gcsweb.istio.io/gcs/istio-prerelease/daily-build/
* Images: gcr.io/istio-release

## Monthly/LTS/Patch Release Artifacts Location
* Tarballs: https://github.com/istio/istio/releases
* Images: docker.io/istio
