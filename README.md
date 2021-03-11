![Cribl Logo](images/Cribl_Logo_Color_TM.png)
# Cribl Helm Charts

This is a Helm repository for charts published by Cribl, Inc.

With the advent of the worker group and master Helm charts, we now have a really fast way to deploy an entire distributed Cribl LogStream environment to a Kubernetes cluster.

# Pre-Requisites

Helm needs to be installed on the machine that you will run these commands from. We recommend you install version 3.

On a Mac with Homebrew:

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

The following example creates a distributed with two autoscaled worker groups, "pcilogs" and "system-metrics", using an auth token of `aabc1602-2d11-11eb-8a09-ab47d5170b65`, and also setting an admin password and installing our license.

```shell
helm install ls-master cribl/logstream-master \
  --set "config.groups={pcilogs,system-metrics}" \
  --set config.token="ABCDEF01-1234-5678-ABCD-ABCDEF012345" \
  --set config.adminPassword="<admin password>" \
  --set config.license="<license key>" \
  -n logstream

helm install ls-wg-pci cribl/logstream-workergroup \
  --set config.host="ls-master-internal" \
  --set config.tag="pcilogs" \
  --set config.token="ABCDEF01-1234-5678-ABCD-ABCDEF012345" \
  -n logstream

helm install ls-wg-system-metrics cribl/logstream-workergroup \
  --set config.host="ls-master-internal" \
  --set config.tag="system-metrics" \
  --set config.token="ABCDEF01-1234-5678-ABCD-ABCDEF012345" \
  -n logstream
```

# Upgrading

Upgrading LogStream to new bits is easy. Update the repo and then upgrade each chart version. Add `--version X.Y.Z` if you want to specify a specific version.

```
helm repo update
helm upgrade ls-master cribl/logstream-master -n logstream
helm upgrade ls-wg-pci cribl/logstream-workergroup -n logstream
helm upgrade ls-wg-system-metrics cribl/logstream-workergroup -n logstream
```

# Support

All items in the Cribl Helm Repository are provided via community support - please join our [slack community](https://cribl.io/community/)!
