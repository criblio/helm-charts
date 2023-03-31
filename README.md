![Cribl Logo](images/Cribl_Logo_Color_TM.png)
# Cribl Helm Charts

This is a Helm repository for charts published by Cribl, Inc.
 
We now have a really fast way to deploy an entire distributed Cribl Stream environment to a Kubernetes cluster, using the workergroup and leader Helm charts. 

# Prerequisites

Helm version 3 is required to use these charts.

To install Helm on (e.g.) a Mac, using Homebrew:

```
brew install helm
```

Instructions for other operating systems can be found here: https://helm.sh/docs/intro/install/

# Deploying

Add the Cribl Helm repo.

```
helm repo add cribl https://michalbiesek.github.io/helm-charts/
```


This will deploy scope Helm chart and send metrics & events to `cribl-internal:10090`.

```
helm install appscope cribl/appscope --set config.criblDestination="tcp://cribl-internal:10090"
```

```
# Optionally modify the default namespace so every new pod will be scoped
kubectl label namespace default scope=enabled
```

# Support

Our community supports all items in the Cribl Helm repository – Please join our [Slack Community](https://cribl.io/community/)!
