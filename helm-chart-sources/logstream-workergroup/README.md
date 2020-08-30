# logstream-workergroup

This Chart deploys a Cribl LogStream worker group.

# Values to Override

* config.tag - tag/group to include in the URL (included as both a group value and a tag value) - defaults to "criblmaster"

* config.token - the authentication token for your logstream master - defaults to "kubernetes"

* config.host - the resolveable hostname of your logstream master - defaults to "logstream-master"

# Install

First, add the Cribl Helm Repo to your helm environment.

`helm repo add cribl https://criblio.github.io/helm-charts/`

To  install the chart with the name "logstream-wg":

`helm install logstream-wg cribl/logstream-workergroup`

To install the chart using the logstream master 'logstream.lab.cribl.io'

`helm install logstream-wg cribl/logstream-workergroup --set config.host='logstream.lab.cribl.io`

To install the chart using the logstream master 'logstream.lab.cribl.io' in the namespace "cribl-helm"

`helm install logstream-wg cribl/logstream-workergroup --set config.host='logstream.lab.cribl.io` -n cribl-helm
