![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# logstream-workergroup Helm Chart

This Chart deploys a Cribl LogStream worker group.

# DISCLAIMER

This chart is a work in progress - it is provided as is.

# Deployment

As built, this chart will deploy a simple worker group for Cribl LogStream, consisting of a deployment, a service, and a horizontal pod autoscaler config, as well as a secret used for configuration. 

This chart does **not** deploy a master node - it depends on one already being present.

![Deployment Diagram](images/k8s-logstream-worker-group.svg)

# Pre-Requisites

1. Helm (preferably v3) installed - instructions are [here](https://helm.sh/docs/intro/install/)
1. Cribl helm repo configured. To do this:
	`helm repo add cribl https://criblio.github.io/helm-charts/`

# Values to Override

This section covers the most likely values to override. To see the full scope of values available, run `helm show values cribl/logstream-workergroup`. 

|Key|Type|Default Value|Description|
|---|----|-------------|-----------|
|config.tag|String|kubernetes|tag/group to include in the URL (included as both a group value and a tag value) - defaults to "criblmaster"|
|config.token|String|criblmaster|the authentication token for your logstream master - defaults to "kubernetes"|
|config.host|String|logstream-master|the resolveable hostname of your logstream master - defaults to "logstream-master"|
|config.rejectSelfSignedCerts|Number|0|0 - allow self-signed certs, 1 - deny self-signed certs|
|service.ports|Array of Maps|<pre>- name: tcpjson<br>  port: 10001<br>  protocol: TCP<br>- name: s2s<br>  port: 9997<br>  protocol: TCP<br>- name: http<br>  port: 10080<br>  protocol: TCP<br>- name: https<br>  port: 10081<br>  protocol: TCP<br>- name: syslog<br>  port: 5140<br>  protocol: TCP<br>- name: metrics<br>  port: 8125<br>  protocol: TCP<br>- name: elastic<br>  port: 9200<br>  protocol: TCP</pre>|The ports to make available both in the Deployment and the Service. Each "map" in the list needs the following values set: <dl><dt>containerPort</dt><dd>the port to be made available</dd><dt>name</dt><dd>a descriptive name of what the port is being used for</dd><dt>protocol</dt><dd>the protocol in use for this port (UDP/TCP)</dd></dl>|
|service.annotations|String|None|Annotations for the the service component - this is where you'll want to put load balancer specific configuration directives|
|criblImage.tag|String|2.4.0|The container image tag to pull from. By default this will use the version equivalent to the Chart's `appVersion` value, but you can override it with "latest" to get the latest release, or to a version number to pull a specific version of LogStream|
|autoscaling.minReplicas|Number|2|The minimum number of LogStream pods to run.|
|autoscaling.maxReplicas|Number|10|The maximum number of LogStream pods to scale to run.|
|autoscaling.targetCPUUtilizationPercentage|Number|50|The CPU utilization percentage that triggers scaling action|
|rbac.create|Boolean|false|Enable Service Account Role & Binding Creation|
|rbac.resources|List|["pods"]|Set the resource boundary for the role being created (K8s resources)|
|rbac.verbs|List|["get", "list"]|Set the API verbs allowed the role (default is read ops)|

### A Note About Versioning

We recommend that you use the same version of the Cribl LogStream code on master nodes and workergroup nodes. If you're not making the move to 2.4.0 on your master yet, make sure to override the `criblImage.tag` value in the install with the version you are running.


## EKS Specific Values
In the case of an EKS deployment, there are many annotations that can be made for the load balancer. Internally, we usually use the annotations for logging to S3, like this:

```
    service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "5"
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: "<bucket name>"
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: "ELB"
```

for a fairly exhaustive lists of annotations you can use with AWS's Elastic Load Balancers, see the [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/) page.

# Install


* To  install the chart with the release name "logstream-wg":

 `helm install logstream-wg cribl/logstream-workergroup`

* To install the chart using the logstream master 'logstream.lab.cribl.io'

 `helm install logstream-wg cribl/logstream-workergroup --set config.host='logstream.lab.cribl.io`

* To install the chart using the logstream master 'logstream.lab.cribl.io' in the namespace "cribl-helm"

 `helm install logstream-wg cribl/logstream-workergroup --set config.host='logstream.lab.cribl.io' -n cribl-helm`
 
# Upgrading

This is done simply using the helm upgrade command. It's important to ensure your helm repository cache is up to date, so the first command is:

```
helm repo update
```

After this step, invoke `helm upgrade <release> -n <namespace> cribl/logstream-workergroup`. For the example above, where the release is "logstream-wg" and is installed in the "cribl-helm" namespace, the command would be:

```
helm upgrade logstream-wg -n cribl-helm cribl/logstream-workergroup
```

This helm chart's upgrade is idempotent, so you can use the upgrade mechanism to upgrade, but also use it as displayed below for changing it's configuration. 
 
# Optional: Kubernetes API Access
In version 2.4.0 (and beyond), an option has been added to create the access mechanisms for the workergroup to be able to access the Kubernetes API. There are four options in the values file for this:

* rbac.create - enables the creation of a Service Account, Cluster Role and Role Binding (which binds the first two together) for the release
* rbac.resources - specifies the Kubernetes API resources that will be available to the release
* rbac.verbs - specifies the API verbs that will be available to the release

For more info on the verbs and resources available, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/). 

# Changing Configuration

Once you have a installed release, you can get the values.yaml file from it by using the helm get values command. For example, with the release name "logstream-wg", the command line would look like this:

```
helm get values logstream-wg -o yaml > values.yaml
```

This will create a values.yaml file with the values in the running release, including any overridden values that you specified when installed. You can make changes to that file, and then use the helm upgrade operation to "upgrade" the release with the new configuration.

For example, if you want to add an additional TCP based syslog port to the release to listen on port 5141 to the "logstream-wg" release, you'd add:

```
  - name: syslog
    port: 5141
    protocol: TCP
```

to the services section, in the ports subsection of the values.yaml file, and then run:

```
helm upgrade logstream-wg cribl/logstream-workergroup -f values.yaml
```

Remember, if you installed in a namespace, you need to include the `-n <namespace>` option to any helm command. You'll still have to create the source in your logstream master, commit and deploy it to your worker group.

# Known Issues

* The chart currently supports *only* TCP ports on the worker group services. This may be addressed in future versions.

# More Info

For additional documentation on this chart, see the [Cribl Docs](https://docs.cribl.io/docs/deploy-kubernetes-helm) page about it.

# Support/Feedback

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) in the #kubernetes channel.
