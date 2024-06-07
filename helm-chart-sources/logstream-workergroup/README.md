![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# logstream-workergroup Helm Chart

This chart deploys a Cribl Stream worker group.

# IMPORTANT
Versions starting with 3.4.0 include a change to the syntax for RBAC values. Before you upgrade the chart from pre-3.4.0 versions, please see the [table below](#values) for current options for the `rbac.apiGroups`, `rbac.verbs`, and `rbac.resources` values.

# New Capabilities
* Support for the 4.7.1 version of Cribl Stream (default version)

# Deployment

As built, this chart will deploy a simple worker group for Cribl Stream, consisting of a deployment, a service, and a horizontal pod autoscaler config, as well as a secret used for configuration. 

This chart does **not** deploy a leader node – it depends on that node's already being present.

![Deployment Diagram](images/k8s-logstream-worker-group.svg)

# Prerequisites

1. Helm (preferably v3) installed – instructions are [here](https://helm.sh/docs/intro/install/).
2. Cribl helm repo configured. To do this:
	`helm repo add cribl https://criblio.github.io/helm-charts/`

# <span id="values"> Values to Override </span>

This section covers the most likely values to override. To see the full scope of values available, run `helm show values cribl/logstream-workergroup`. 

|Key|Default Value|Description|
|---|-------------|-----------|
|config.group|"criblleader"|Tag/group to include in the URL (included as both a group value and a tag value). |
|config.tag|deprecated|This option is deprecated, but still supported for backward compatibility. |
|config.token|"criblleader"|The authentication token for your Cribl Stream leader. |
|config.host|"logstream-leader"|The resolvable hostname of your Cribl Stream leader. |
|config.useExistingSecret|`false`|Setting this value to `true` disables the creation of a `CRIBL_DIST_MASTER_URL` string. You are responsible for attaching it using the `envValueFrom` config. See below for an example.|
|config.rejectSelfSignedCerts|0| One of: `0` – allow self-signed certs; or `1` – deny self-signed certs. |
|config.tlsLeader.enable|false|Enable TLS connectivity from the workergroup to its leader node |
|config.hostNetwork|false|configures the workergroup to use the K8s host network instead of the container network.|
|config.probes|true|enables (true) or disables (false) the liveness and readiness probes.|
|config.livenessProbe|see `values.yaml`|[livenessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request) configuration|
|config.readinessProbe|see `values.yaml`|[readinessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes) configuration|
|service.type|LoadBalancer|The type of service to create for the workergroup|
|service.loadBalancerIP|none (IP Address)|The IP address to use for the load balancer service interface, if the type is set to LoadBalancer. Check with your Kubernetes setup to see if this is supported. |
|service.ports|<pre>- name: tcpjson<br>  port: 10001<br>  protocol: TCP<br>- name: s2s<br>  port: 9997<br>  protocol: TCP<br>- name: http<br>  port: 10080<br>  protocol: TCP<br>- name: https<br>  port: 10081<br>  protocol: TCP<br>- name: syslog<br>  port: 5140<br>  protocol: TCP<br>- name: metrics<br>  port: 8125<br>  protocol: TCP<br>- name: elastic<br>  port: 9200<br>  protocol: TCP<br>- name: hec<br>  port: 8088<br>  protocol: TCP <br>- name: criblhttp<br>  port: 10200<br>  protocol: TCP<br>- name: cribltcp<br>  port: 10300<br>  protocol: TCP</pre>|The ports to make available both in the Deployment and the Service. Each "map" in the list needs the following values set: <dl><dt>name</dt><dd>A descriptive name of what the port is being used for.</dd><dt>port</dt><dd>The port to make available.</dd><dt>protocol</dt><dd>The protocol in use for this port (UDP/TCP).</dd></dl>|
|service.annotations|{}|Annotations for the service component – this is where you'll want to put load-balancer-specific configuration directives.|
|service.externalTrafficPolicy|see `values.yaml`|Request the client source IP be preserved by setting the value to `Local`. Consult the [Kubernetes documentation](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip) for more information.|
|service.loadBalancerSourceRanges|see `values.yaml`|Allows for third-party load balancers to restrict access the defined IP ranges. Consult the [Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/service/#aws-nlb-support) for more information.|
|ingress|see `values.yaml`|Ingress controller configuration|
|ingress.enable|false|Enable creating Ingress resources|
|criblImage.tag|"3.4.0"|The container image tag to pull from. By default, this will use the version equivalent to the chart's `appVersion` value. But you can override this with "latest" to get the latest release, or with a version number (e.g., "3.4.0") to pull a specific version of Cribl Stream. |
|autoscaling.minReplicas|2|The minimum number of Cribl Stream pods to run.|
|autoscaling.maxReplicas|10|The maximum number of Cribl Stream pods to scale to run.|
|autoscaling.targetCPUUtilizationPercentage|50|The CPU utilization percentage that triggers scaling. |
|autoscaling.behavior|{}|[Scaling behavior configuration](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)|
|rbac.create|false|Enable Service Account Role & Binding Creation. |
|rbac.apiGroups|{core}|Set the apiGroups in roles rules|
|rbac.resources|{pods}|Set the resource boundary for the role being created (K8s resources). |
|rbac.verbs|{get,list}|Set the API verbs allowed the role (defaults to read ops). |
|rbac.annotations|{}|Sets annotations on the Service Account. Useful for [accessing cloud resources through IAM roles](../../common_docs/EKS_SPECIFICS.md#aws-iam-role-for-worker-group).|
|serviceAccount.create|true|Create a ServiceAccount used by the Pods.|
|serviceAccount.name|`undefined`|The ServiceAccount name. If `serviceAccount.create` is true, the ServiceAccount is named this value. If false, the ServiceAccount must already exist.|
|nodeSelector|{}|Add nodeSelector values to define which nodes the pods are scheduled on - see [k8s Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) for details and allowed values. |
|strategy|see `values.yaml`|Add strategy values to define how Pods are upgraded - see k8s Documentation [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy) and [DaemonSet](https://kubernetes.io/docs/tasks/manage-daemon/update-daemon-set/) for details and allowed values.|
|__Extra Configuration Options__|
|[extraVolumeMounts](../../common_docs/EXTRA_EXAMPLES.md#extraVolumeMounts)|{}|Additional Volumes to mount in the container.|
|[extraSecretMounts](../../common_docs/EXTRA_EXAMPLES.md#extraSecretMounts)|[]|Pre-existing secrets to mount within the container. |
|[extraConfigmapMounts](../../common_docs/EXTRA_EXAMPLES.md#extraConfigmapMounts)|{}|Pre-existing configmaps to mount within the container. |
|[extraInitContainers](../../common_docs/EXTRA_EXAMPLES.md#extraInitContainers)|{}|Additional containers to run ahead of the primary container in the pod.|
|[extraContainers](../../common_docs/EXTRA_EXAMPLES.md#extraContainers)|{}|Additional containers to run as sidecars of the primary container in the pod.|
|[securityContext.runAsUser](../../common_docs/EXTRA_EXAMPLES.md#securityContext)|0|User ID to run the container processes under.|
|[securityContext.runAsGroup](../../common_docs/EXTRA_EXAMPLES.md#securityContext)|0|Group ID to run the container processes under.|
|[envValueFrom](../../common_docs/EXTRA_EXAMPLES.md#extraEnvFrom)|{}|Environment variables to be exposed from the Downward API.|
|[env](../../common_docs/EXTRA_EXAMPLES.md#env)|[]|Additional Static Environment Variables.|
|deployment|deployment|One of: "deployment" to deploy as a Deployment Set; or "daemonset" to deploy as a DaemonSet.|
|[rbac.extraRules](../../common_docs/EXTRA_EXAMPLES.md#rbac.extraRules)|{}|Additional RBAC rules to put in place.|

### A Note About Versioning

We recommend that you use the same version of the Cribl Stream code on leader nodes and workergroup nodes. 

# Install


* To install the chart with the release name "logstream-wg":

 `helm install logstream-wg cribl/logstream-workergroup`

* To install the chart using the logstream leader 'logstream.lab.cribl.io'

 `helm install logstream-wg cribl/logstream-workergroup --set config.host='logstream.lab.cribl.io`

* To install the chart using the logstream leader 'logstream.lab.cribl.io' in the namespace "cribl-helm"

 `helm install logstream-wg cribl/logstream-workergroup --set config.host='logstream.lab.cribl.io' -n cribl-helm`
 
# Upgrading

This is done simply using the `helm upgrade` command. It's important to ensure that your Helm repository cache is up to date, so the first command is:

```
helm repo update
```

After this step, invoke `helm upgrade <release> -n <namespace> cribl/logstream-workergroup`. For the example above, where the release is "logstream-wg" and is installed in the "cribl-helm" namespace, the command would be:

```
helm upgrade logstream-wg -n cribl-helm cribl/logstream-workergroup
```

This helm chart's upgrade is idempotent, so you can use the upgrade mechanism to upgrade, but can also use it as displayed [below](#changing) for changing its configuration. 
 
# Optional: Kubernetes API Access

Versions 2.4.0+ include access mechanisms for worker groups to access the Kubernetes API. Four options are available in the `values.yaml` file for this:

* `rbac.create` – enables the creation of a Service Account, Cluster Role, and Role Binding (which binds the first two together) for the release.
* `rbac.resources` – specifies the Kubernetes API resources that will be available to the release.
* `rbac.verbs` – specifies the API verbs that will be available to the release.
* `rbac.extraRules` – additional rulesets for the cluster role.

Additionally, you may customize the ServiceAccount resource utilized by the chart:

* `serviceAccount.create` - controls if a ServiceAccount resource is created during chart deployment.
* `serviceAccount.name` - the configured name of the ServiceAccount. If `serviceAccount.create` is `true`, the ServiceAccount is named this value. If `false`, then the ServiceAccount must already exist and is mapped in the RoleBinding.

For more info on the verbs and resources available, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/). 

# <span id="changing"> Changing Configuration </span>

Once you have an installed release, you can get the `values.yaml` file from it by using the `helm get values` command. For example, with the release name "logstream-wg", the command line would look like this:

```
helm get values logstream-wg -o yaml > values.yaml
```

This will create a `values.yaml` file with the values in the running release, including any overridden values that you specified when installed. You can make changes to that file, and then use the `helm upgrade` operation to "upgrade" the release with the new configuration.

For example, if you want to add an additional TCP-based syslog port to the release, to listen on port 5141 to the "logstream-wg" release, you'd add:

```
  – name: syslog
    port: 5141
    protocol: TCP
```

...to the `values.yaml` file's `service` > `ports` subsection, and then run:

```
helm upgrade logstream-wg cribl/logstream-workergroup -f values.yaml
```

Remember, if you installed in a namespace, you need to include the `-n <namespace>` option to any `helm` command. You'll still have to create the source in your Cribl Stream leader, and commit and deploy it to your worker group.

# Using Persistent Storage for Persistent Queueing

With the addition of the `extraVolumeMounts` capability, it is now feasible to use persistent volumes for Cribl Stream persistent queueing. However there is variability in persistent-storage implementations, and this variability can lead to problems in scaling workergroups, and we recommend only implementing this if you have confidence in your persistent storage implementations. If you choose to implement persistent volumes for queueing, please consider these suggestions:

1. Use a shared-storage-volume mechanism. We've worked with the EFS CSI driver for AWS, and it works fairly well (though it can be a little tedious to configure).
2. Understand your Kubernetes networking topology, and how it interacts with your persistent storage driver. (For example, if you're in AWS, ensure that your volumes are available in all Availability Zones that your nodes might run in.) 
3. Monitor the workergroup pods for volume issues. The faster you can see such issues and react, the more likely that you'll be able to resolve them.

# Using an Existing Secret

To use an existing secret in your Kubernetes deployment, setting the `config.useExistingSecret` value to `true` disables automatic creation of a `CRIBL_DIST_MASTER_URL` string. You are responsible for generating this Environment Variable by yourself and attaching it using the `envValueFrom` setting. See the Cribl Docs for more details on [how to construct this URL](https://docs.cribl.io/stream/environment-variables/#format).

```yaml
config:
  useExistingSecret: true

envValueFrom:
  - name: CRIBL_DIST_MASTER_URL
    valueFrom:
      secretKeyRef:
        name: <secretName>
        key: <secretKey>
```

# Known Issues

* The chart currently supports *only* TCP ports on the worker group services. This may be addressed in future versions.
* [EKS-Specific Issues](../../common_docs/EKS_SPECIFICS.md).


# More Info

For additional documentation on this chart, see the [Cribl Docs](https://docs.cribl.io/stream/deploy-kubernetes) page about it.

# Support/Feedback

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) and navigate to the `#kubernetes` channel.
