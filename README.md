# daily-release

This repo tracks latest daily release. Identified with a image hub and tag, each
release candidate must pass the qualification before proceeding to the next stage
in the release pipeline. The release qualification runs the e2e test suite in
multiple configurations in parallel. It is triggered by creating a pull request
against master. See
[`istio/test-infra/toolbox/githubctl`](https://github.com/istio/test-infra/tree/master/toolbox/githubctl)
for the tool that does so. Complete release process can be found
[here](https://github.com/istio/istio/blob/master/release/README.md). 

## Design

### Separate Repository to Track Release Candidate

We track this history of release candidates with GitHub repository. It is under
istio-releases rather than istio, a different org since we would like to keep the
source in istio and infrastructure elsewhere.  The most critical file is the
`test/greenBuild.VERSION`. An example is shown below. 

```
export HUB="gcr.io/laane-istio-dev"
export TAG="0.5.0-pre20180122-20-31-00"
export ISTIO_REL_URL="https://storage.googleapis.com/laane-istio-dev-builds/daily-build/0.5.0-pre20180122-20-31-00/"
export TIME=1517304965594224249
```

### Pull Requests to Trigger Qualification

Tests are set up as presubmit checks and triggered by creating a pull request to
update the `test/greenBuild.VERSION`. Each e2e test will source this file first so it
tests with the specific artifacts the pipeline specified. The TIME attribute allows
repeated qualifications on the same artifacts. 

One should not edit this file or create a pull request by hand. We built a
command-line tool named `githubctl` that does the following

* Edit test/greenBuild.VERSION for with values passed through command line flags
* Create a pull request with such changes against master
* Fetch the list of required checks, poll their results until all jobs have
finished or timeout
* Automatically Merge this pull request if all required checks have passed
* Exit with nonzero status code if any required check failed

Whether a check is *required* is defined by repo admin through GitHub as branch
protection mechanism. It is simple to toggle on and off of each test, for example
if a test has been flaky or deprecated it could be muted temporarily, or if
flakiness has been resolved it could be added back. 

Another advantage of defining qualification through GitHub is that jobs running on
different CI service could all be part of the release qualification. Istio is an
open-source endeavor, and on presubmit about half of the jobs are running on
[CircleCI](https://github.com/istio/istio/wiki/Working-with-CircleCI).
Moving forward, if new jobs added on release qualification needs to run on
CircleCI, we only need to set up the webhook to trigger the jobs and no code change
is needed. GitHub provides REST API for easy and authenticated automation, allowing
clients to check the results of tests on pull requests, fetch the list of required
checks, and perform the auto-merging onto master. 

## E2E Configurations

All release qualification runs on a separate cluster from the one used for pre/post
submit to reduce resource contention. It requires the alpha features on GKE and as a
result the cluster expires 30 days after its creation. 

By the 0.5.0 release, the entire e2e suite contains three sets of tests -- bookinfo,
mixer, and simple. As shown earlier, multiple jobs are triggered for the
qualification, each running the complete e2e suite with different configuration. The
list is 

```
auth:          whether authentication is enabled
default-proxy: whether to use the default proxy baked in istioctl
cluster-wide:  false if namespace as isolation boundary
skew:          takes a list of release versions to do version skew test
               between control plane and sidecars
```

More information on the e2e test and framework can be found
[here](https://github.com/istio/istio/blob/master/tests/e2e/README.md).
One major difference of the release qualification from the istio presubmit is that
rather than building artifacts at the current commit, we need to qualify/test the
specific build made upstream in the release pipeline. Thus, we have made sure that
we consume the exact artifacts we just built.

## Common Pitfalls

### Resource Quota and Cluster Rotation

Rarely resources claimed in previous test runs are not successfully released. Since
clusters for presubmit, postsubmit, daily release are running in the same GCP
project, the leaking resources might eventually max out our project quota. Seb has
been working on cluster preprovision to provide fast, hermetic, disposable test
environment and hopefully mitigate this issue. It is a good idea to check the quota
status on Pantheon when one sees change-unrelated failures.

Istio requires GKE alpha features for e2e tests. Clusters with alpha features
expires 30 days after its creation and it auto-deleted after expiration. It is
important to ensure that the cluster exists. Before it expires, use
[`test-infra/scripts/update-e2e-cluster.sh`](https://github.com/istio/test-infra/tree/master/scripts)
to create a new cluster and rotate all jobs to it. 

### Registry/Bucket Permission

The qualification tests pull specified docker images and istioctl binary from a hub
and tag. Currently, all qualification jobs run on Prow under the service account
`istio-prow-test-job@istio-testing.iam.gserviceaccount.com`. It is important that
this account is permitted to access the registry and bucket where the artifacts one
wants to test is stored. Often, if you see ErrImagePull on a container when the e2e
framework tries to set up istio, the access control is often at fault. If you
experience a crash loop when bringing up containers, then often it is the image
format problem. It could be the directory is wrong/empty so the image one is using
is essentially empty, or it could be problems from the upstream build system.

### GitHub-related Flakes

This is transient but it does happen that GitHub webhook might fail to push
notifications to Prow (or other listening CI systems). Then GitHub waits for the
test results but jobs are not triggered on Prow. In recent upgrade, `githubctl` has
handled this scenario and would conclude qualification fails. It also helps to
visit [prow.istio.io](prow.istio.io) to check the job status.

Rarely, but if multiple pull requests are in flight and two of them pass the
qualification, they will be auto-merged to master. The second pull request to be
merged will have a conflict and exit with nonzero status. Looking at the log or
visit GitHub pull request page will give you clear information on whether the
qualification fails because of test failure of conflicts.
