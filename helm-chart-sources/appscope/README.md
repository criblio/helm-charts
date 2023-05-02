![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# Appscope Helm Chart

This Helm chart deploys [Appscope](https://appscope.dev/) in a Kubernetes Cluster.

# Prerequisites

1. Helm v3 installed – instructions are [here](https://helm.sh/docs/intro/install/).
2. Cribl Helm repo configured. App the repo locally with the following command:
    `helm repo add cribl https://criblio.github.io/helm-charts/`


# Configuration

As built, this chart will deploy to a Kubernetes cluster an AppScope Deployment, Service, Mutating Webhook Admission Controller, Service Account, Cluster Role, Cluster Role Binding, and Secret for setting the AppScope configuration. 

The required options to deploy this chart is the `cribl` when sending to a Cribl destination, or `metrics` and `events` when sending to non Cribl destinations.

For all the available command line options, see [Values to Override](#values-to-override). 

## Basic Configuration for Cribl Stream

To define a TCP-based connection to Cribl Stream on Cribl.Cloud, install the chart with the with the `cribl` config value defined as: `in.main-default-<organization>.cribl.cloud:10091`:

 `helm install appscope cribl/appscope --set appscope.destinations.cribl="tcp://in.main-default-<your-organization>.cribl.cloud:10091"`

By default, Cribl.Cloud-managed instances of Cribl Stream have port `10091` configured to use TCP, and a built-in AppScope Source to receive data from AppScope. 

To send metrics & events to a [Stream](https://cribl.io/stream/) instance in the same Kubernetes cluster, deploy with chart with the `cribl` config value defined as: `cribl-internal:10090`:

 `helm install appscope cribl/appscope --set appscope.destinations.cribl="tcp://cribl-internal:10090"`

## Basic Configuration for Statsd Prometheus Exporter

To send `statsd` metrics to a local Statsd Exporter deployment, use the following configuration:

```yaml
# Appscope configuration 
appscope:
  destinations: 
    metrics: <prometheus-statsd-exporter-name>.<namespace>:9125
    format: "statsd"
```

# Support/Feedback

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) and navigate to the `#appscope` or `containers` channel.

# More Info

For additional documentation about the values used in this chart, see the [Cribl Docs](https://appscope.dev/docs/cli-reference/#k8s) page.

# Values to Override

This section covers the most likely values to override. To see the full scope of values available, run `helm show values cribl/appscope`.

| Key                                                                            | Default Value     | Description                                        |
|--------------------------------------------------------------------------------|-------------------|----------------------------------------------------|
| image.repository                                                               | `cribl/scope`     | Docker image repository to pull images             |
| image.pullPolicy                                                               | `Always`          | When will the Node pull the image                  |
| image.tag                                                                      | `1.3.2`           | The Version of Appscope to deploy                  |
| imagePullSecrets                                                               | `[]`              | Credentials to pull container images               |
| appscope.destinations.cribl                                                    |                   | Cribl Stream destination for metrics & events      |
| appscope.destinations.metrics                                                  |                   | Destination for Metrics                            |
| appscope.destinations.events                                                   |                   | Destination for Events                             |
| appscope.token                                                                 |                   | AuthToken for Cribl Stream                         |
| appscope.destinations.format                                                   | `ndjson`          | Format of metrics output (statsd|ndjson)           |
| appscope.debug                                                                 | `false`           | Enable logging in the scope webhook container      |
