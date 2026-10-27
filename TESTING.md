# How this chart is tested

# Automated tests

Every pull request to the master branch triggers the following tests:

* kube-score
* helm unittest
* ct lint
* ct install, against several Kubernetes versions using kind

[![Lint and Test Charts](https://github.com/docker-mailserver/docker-mailserver-helm/actions/workflows/on-push-lint-charts.yml/badge.svg)](.github/workflows/on-push-lint-charts.yml)

The versions of Helm, helm-unittest and the other tools are pinned at the top of [the workflow](.github/workflows/on-push-lint-charts.yml).


# Local testing

If you're submitting a PR, and you want to ensure your changes will pass automated testing (above), here are your options:

## Unit tests

Unit tests use [helm-unittest](https://github.com/helm-unittest/helm-unittest). Most of them compare the rendered manifests against snapshots in `charts/docker-mailserver/tests/__snapshot__`. If you change the templates or default values, regenerate the snapshots and check the diff.

Snapshot output depends on the helm-unittest version, so install the same version as CI (`HELM_UNITTEST_VERSION` in the workflow):

```console
helm plugin install https://github.com/helm-unittest/helm-unittest.git --version v1.2.1 --verify=false
helm unittest charts/docker-mailserver        # run the tests
helm unittest -u charts/docker-mailserver     # update the snapshots
```

Leave out `--verify=false` on Helm 3.

## Linting

We use helm's [chart-testing](https://github.com/helm/chart-testing) tool to lint our charts. The tool can be installed locally, or it can be run in a Docker container.

To run in Docker:

1. Have Docker installed
2. Run `.ci/scripts/local-ct-lint.sh`

To run locally:

1. Have ct installed (Get a binary package from https://github.com/helm/chart-testing/releases)
2. Run `ct lint --config=.ci/ct-config.yaml`

## Deployment testing

*ct* can also test a chart by deploying it to a temporary namespace in a Kubernetes cluster, and waiting for indications that the deployment has been successful. This is a good way to test how the deployment behaves "for real".

ct lint --config=.ci/ct-config.yaml

Create a KinD cluster, by running `kind create cluster`:

```
❯ kind create cluster
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.17.0) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a nice day! 👋
```

Trigger a `ct install` test against the KinD cluster, by running `ct install --config=.ci/ct-config.yaml`. **ct** will target your current context (be careful if you've got multiple contexts configured!), create a temporary namespace, and deploy the chart into that namespace, until `helm --wait` indicates success. After this, the helm release will be removed, the namespace deleted, and you can retire your KinD cluster by running `kind delete cluster`.
