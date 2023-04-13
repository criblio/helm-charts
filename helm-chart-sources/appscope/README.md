![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# Appscope Helm Chart

This chart deploys an Appscope in a Kubernetes Cluster.

# Install

* To install the chart with the release name "appscope" and send metrics & events to Cribl Stream defined as: `cribl-internal:10090`:

 `helm install appscope cribl/appscope --set config.criblDestination="tcp://cribl-internal:10090"`

# Support/Feedback

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) and navigate to the `#containers` channel.

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
| config.criblDestination                                                        |                   | Cribl Stream destination for metrics & events      |
| config.metricDestination                                                       |                   | Destination for Metrics                            |
| config.eventDestination                                                        |                   | Destination for Events                             |
| config.token                                                                   |                   | AuthToken for Cribl Stream                         |
| config.metricFormat                                                            | `ndjson`          | Format of metrics output (statsd|ndjson)           |
| config.namespace                                                               | `default`         | Name of the namespace in which to install          |
| config.debug                                                                   | `false`           | Enable logging in the scope webhook container      |

