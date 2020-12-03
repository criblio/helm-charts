![Cribl Logo](images/Cribl_Logo_Color_TM.png)
# Cribl Helm Charts

This is a HELM repository for charts published by Cribl, Inc. 

# Pre-Requisites

Every chart contained herein has, at least, the same basic pre-requisites:

1. Helm (preferably v3) installed - instructions are [here](https://helm.sh/docs/intro/install/)
1. Cribl helm repo configured. To do this:
	`helm repo add cribl https://criblio.github.io/helm-charts/`

# Deploying a complete distributed system

With the advent of the workergroup *and* master helm charts, we now have a really fast way to deploy an entire distributed Cribl LogStream environment in a kubernetes cluster. For example, if we want to create a distributed which has two autoscaled worker groups, "pcilogs" and "system-metrics", using an auth token of `aabc1602-2d11-11eb-8a09-ab47d5170b65`, and also setting an admin password and installing our license all into the "logstream" kubernetes namespace, we'd use these 3 commands.

```
helm install ls-master cribl/logstream-master --set config.groups=\{pcilogs,system-metrics\} --set config.token="aabc1602-2d11-11eb-8a09-ab47d5170b65" --set config.adminPassword='<admin password>' --set config.license='<license key>'  -n logstream

helm install ls-wg-pci cribl/logstream-workergroup --set config.host="ls-master-internal" --set config.tag="pcilogs" --set config.token='aabc1602-2d11-11eb-8a09-ab47d5170b65' -n logstream

helm install ls-wg-system-metrics cribl/logstream-workergroup --set config.host="ls-master-internal" --set config.tag="system-metrics" --set config.token='aabc1602-2d11-11eb-8a09-ab47d5170b65' -n logstream

```


# Support

All items in the Cribl Helm Repository are provided via community support - please join our [slack community](https://cribl.io/community/)!
