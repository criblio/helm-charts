![Cribl Logo](images/Cribl_Logo_Color_TM.png)
# Cribl Helm Charts

This is a Helm repository for charts published by Cribl, Inc.

With the advent of the workergroup and leader Helm charts, we now have a really fast way to deploy an entire distributed Cribl LogStream environment to a Kubernetes cluster.

# Prerequisites

Helm version 3 is required to use these charts.

To install Helm on (e.g.) a Mac, using Homebrew:

```
brew install helm
```

Instructions for other operation systems can be found here: https://helm.sh/docs/intro/install/

# Deploying

If you haven't done so already, create a namespace. Our documentation example uses `logstream`.

```
kubectl create namespace logstream
```

Add the Cribl Helm repo.

```
helm repo add cribl https://criblio.github.io/helm-charts/
```

The following example creates a distributed deployment with two autoscaled worker groups, `pcilogs` and `system-metrics`. It uses an auth token of `ABCDEF01-1234-5678-ABCD-ABCDEF012345`, sets an admin password, and installs our license:

```shell
helm install ls-leader cribl/logstream-leader \
  --set "config.groups={pcilogs,system-metrics}" \
  --set config.token="ABCDEF01-1234-5678-ABCD-ABCDEF012345" \
  --set config.adminPassword="<admin password>" \
  --set config.license="<license key>" \
  -n logstream

helm install ls-wg-pci cribl/logstream-workergroup \
  --set config.host="ls-leader-internal" \
  --set config.tag="pcilogs" \
  --set config.token="ABCDEF01-1234-5678-ABCD-ABCDEF012345" \
  -n logstream

helm install ls-wg-system-metrics cribl/logstream-workergroup \
  --set config.host="ls-leader-internal" \
  --set config.tag="system-metrics" \
  --set config.token="ABCDEF01-1234-5678-ABCD-ABCDEF012345" \
  -n logstream
```

## Running Distributed on a Free License

If you are not specifying a license in your install, and you're looking to run distributed, you'll need to go into LogStream's user interface and accept the Free license. (The Free license allows one worker group.) If you specify the `config.groups` option, the leader will be configured as a distributed leader. If you don't, it will be configured as a single instance. (You can later manually reconfigure it as distributed via LogStream's UI.)

# Upgrading

Upgrading LogStream to new bits is easy. Update the repo, and then upgrade each chart version. The example below updates to the current version, but you can append `--version X.Y.Z` if you want to [specify a particular version](https://helm.sh/docs/helm/helm_upgrade/).

```
helm repo update
helm upgrade ls-leader cribl/logstream-leader -n logstream
helm upgrade ls-wg-pci cribl/logstream-workergroup -n logstream
helm upgrade ls-wg-system-metrics cribl/logstream-workergroup -n logstream
```

# Support

All items in the Cribl Helm repository are provided via community support – please join our [Slack Community](https://cribl.io/community/)!
