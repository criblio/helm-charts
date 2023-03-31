![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# Scope Helm Chart

This chart deploys an Appscope in a Kubernetes Cluster.

# Deployment

* To  install the chart with the release name "logstream-wg" and send events & metrics to `cribl-internal:10090`:

```
    helm install appscope cribl/appscope --set config.criblDestination="tcp://cribl-internal:10090"
```

# Prerequisites

1. Helm v3 installed – instructions are [here](https://helm.sh/docs/intro/install/).
2. Cribl helm repo configured. To do this:
    `helm repo add cribl https://michalbiesek.github.io/helm-charts/`

# Support/Feedback

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) and navigate to the `#containers` channel.
