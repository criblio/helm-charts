![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# logstream-master Helm Chart

This Chart deploys a Cribl LogStream master server.

# DISCLAIMER

This chart is a work in progress - it is provided as is.

# Deployment

As built, this chart will deploy a Cribl LogStream Master Server, consisting of a deployment, two services, and a number of persistent volumes. 

![Deployment Diagram](images/k8s-logstream-master.svg)

Of special note is the fact that two load balanced services are created - the main one (named after the helm release), which is intended as the primary service interface for users, and the "internal" one (named <helm-release>-internal), which is intended for the workergroup to master communication.

# Pre-Requisites

## Helm Setup

1. Helm (preferably v3) installed - instructions are [here](https://helm.sh/docs/intro/install/)
1. Cribl helm repo configured. To do this:
	`helm repo add cribl https://criblio.github.io/helm-charts/`

## Persistent Storage

The chart requires persistent storage; it will use your default storage class, or you can override (`config.scName`) with the name of a storage class to use. This has primarily been tested using AWS EBS storage via the CSI EBS driver. The volumes are created as ReadWriteOnce claims. For more info on Storage Classes, see the [Kubernetes.IO Storage Classes page](https://kubernetes.io/docs/concepts/storage/storage-classes/).

## AWS Specific Notes

If you're running on EKS, it's highly recommended that you use AZ specific node groups (see the [eksctl.io Autoscaling Doc](https://eksctl.io/usage/autoscaling/) for details on doing this). IF you are doing autoscaling in your cluster nodes in a single node group that spans AZ's, you *may* run into trouble mounting volumes (as EBS volumes are AZ specific).


# Values to Override

This section covers the most likely values to override. To see the full scope of values available, run `helm show values cribl/logstream-master`. 



|Key|Default Value (or type)|Description|
|---|----|-------------|
|config.adminPassword|String|The password you want the admin user to have set.|
|config.token|String|The auth key you want to set up for worker access. The LogStream instance is only configured as a distributed master server if this value is set. This can, of course, also be configured via the LogStream UI|
|config.license|String|The license for your logstream instance. If you do not set this, it will default to the "free" license. You can change this in the LogStream UI as well.|
|config.groups|[]|The group names to configure for the master instance - this will create a mapping for each group which looks for the tag `<groupname>`, and will create the basic structure of each groups configuration.|
|config.scName|default storage class|the StorageClass Name for all of the persistent volumes.|
|config.rejectSelfSignedCerts|0|0 - allow self-signed certs, 1 - deny self-signed certs|
|config.healthPort|9000|the port to use for health checks (readiness/live)|
|service.ports|[]|<pre>- name: api<br>  port: 9000<br>  protocol: TCP<br>  external: true<br>- name: mastercomm<br>  port: 4200<br>  protocol: TCP<br>  external: false</pre>|The ports to make available both in the Deployment and the Service. Each "map" in the list needs the following values set: <dl><dt>containerPort</dt><dd>the port to be made available</dd><dt>name</dt><dd>a descriptive name of what the port is being used for</dd><dt>protocol</dt><dd>the protocol in use for this port (UDP/TCP)</dd><dt>external</dt><dd>Set to true to be exposed on the external service, or false not to</dd></dl>|
|service.annotations|{}|Annotations for the the service component - this is where you'll want to put load balancer specific configuration directives|
|criblImage.tag|2.4.5|The container image tag to pull from. By default this will use the latest release, but you can also use version tags (like "2.3.2") to pull specific versions of LogStream|
|consolidate_volumes|boolean|If this value exists and the helm command is "upgrade", this will use the split volumes that we created in charts before 2.4 and consolidate them down to one config volume. This is a ONE TIME event.|
|__Extra Configuration Options__|
|[extraVolumeMounts](../../common_docs/EXTRA_EXAMPLES.md#extraVolumeMounts)|{}|Additional Volumes to Mount in the container.|
|[extraSecretMounts](../../common_docs/EXTRA_EXAMPLES.md#extraSecretMounts)|[]|Pre-existing secrets to mount within the container. |
|[extraConfigmapMounts](../../common_docs/EXTRA_EXAMPLES.md#extraConfigmapMounts)|{}|Pre-existing configmaps to mount within the container. |
|[extraInitContainers](../../common_docs/EXTRA_EXAMPLES.md#extraInitContainers)|{}|Additional containers to run ahead of the primary container in the pod.|
|[securityContext.runAsUser](../../common_docs/EXTRA_EXAMPLES.md#securityContext)|0|User ID to run the container processes under.|
|[securityContext.runAsGroup](../../common_docs/EXTRA_EXAMPLES.md#securityContext)|0|Group ID to run the container processes under.|
|[envValueFrom](../../common_docs/EXTRA_EXAMPLES.md#extraEnvFrom)|{}|Environment Variables to be exposed from the Downward API.|
|[env](../../common_docs/EXTRA_EXAMPLES.md#env)|[]|Additional Static Environment Variables.|
|ingress.enable|false|Enable Ingress in front of the external service. Setting this to true changes the external service to type NodePort, and creates an ingress that connects to it.|
|ingress.annotations|{}|If ingress.enable is set to true, this is where annotations to configure the specific ingress controller. _*NOTE: Ingress is only supported on Kubernetes 1.19 and later clusters*_|


# Basic Installation

* To  install the chart with the release name "logstream-master":

  `helm install logstream-master cribl/logstream-master`


* To install the chart using the storage class "ebs-sc"

  `helm install logstream-master cribl/logstream-master --set config.scName='lebs-sc`
  
# Post-Install/Post-Upgrade

LogStream will not automatically deploy changes to the worker nodes, so you'll need to go into the LogStream UI, and [commit and deploy changes](https://docs.cribl.io/docs/deploy-distributed) for all of your worker groups. 


# LogStream Configuration Overrides

The helm chart, without any values overrides, creates effectively a standalone instance of Cribl LogStream, using the standard container image. One can, if they so choose, configure distributed mode, licensing, admin user passwords, etc., all from the logstream UI. However, you can install with value overrides to change that.

* Applying a License

  If you have a standard or enterprise license, you can add it as an override to your install using the config.license parameter:

  `helm install logstream-master cribl/logstream-master --set config.license="<long encoded license string redacted>"`
  
* Running Distributed on a Free License

If you are not specifying a license, you'll need to go into the user interface for logstream and accept the free license. If you specify the groups option, the master will be configured as a distributed master. If you don't, it will be configured as a standalone instance. 

* Setting the admin password

  Normally, when you first install logstream and log into the UI, it forces you to change your password. You can skip that by setting your admin password via the config.adminPassword parameter:

  `helm install logstream-master cribl/logstream-master --set config.adminPassword="<new password>"`

* Setting up Worker Groups/Mappings

  As mentioned above, the default is to install a vanilla deployment of LogStream. If you are deploying as a master, you can use the `config.groups` parameter to define the worker groups you want created and mapped. each group in the list you provide will be created as a worker group, with a mapping rule to look for a tag with the worker group name in it. 

  `helm install logstream-master cribl/logstream-master --set config.groups={group1,group2,group3}`

  The example above will create three worker groups: `group1`, `group2`, and `group3`, and a mapping rule for each.


# Upgrading from a pre-2.4.0 version
**NOTE**: This has changed in the 2.4.5 version.

In LogStream 2.4.0, the introduction of the `$CRIBL_VOLUME_DIR` environment variable simplifies the persistent storage requirement for logstream-master. Instead of maintaining 4 separate persistent volumes (one each for $CRIBL_HOME/{data,state,local,groups}), they can all be consolidated into a single volume. 

In the helm chart, we handle this via the helm upgrade command. If you are upgrading from a pre-2.4 version of the chart, you'll want to set the 'consolidate_volumes' value, which will create a new, larger, volume and consolidates the data from the original volumes to it. This is done via an initContainer that handles the logistics. When it finishes, and the logstream-master pod comes back up, it is with a single consolidated volume. 

## WARNING: BACK UP YOUR DATA FIRST

While we've tested this upgrade multiple times, there are always differences in environments that can cause problems. As a result, we recommend that you back up the data before running the upgrade command. This is best done with a combination of kubectl and tar:

```
kubectl exec <pod name> -n <namespace> -- bash -c "cd /opt/cribl; tar cf - {state,data,local,groups}" > cribl_backup.tar
```

This command executes the tar based back up of all four volumes, and outputs it to a local tar file (cribl_backup.tar)

## Running the Upgrade
Helm makes upgrades easy, as you just need to run `helm repo update` to ensure you have the latest repo updates available, followed by `helm upgrade` to actually upgrade the containers.

For example, if you've installed the helm charts in the `logstream` namespace, named your release "ls-master", and set up your helm repo per the pre-reqs section (i.e. named it "cribl"), run the following:

```
helm repo update
helm upgrade ls-master --set consolidate_volumes=true -n logstream cribl/logstream-master
```

## Upgrade Order of Operations

While there should be no major problems running a 2.4.0 master and 2.3.4 workers, it's not recommended. Cribl recommends that you upgrade the master helm chart first, and then upgrade the workers (see [logstream-workergroup/README.md](/criblio/helm-charts/logstream-worker/README.md) for details). 

### Idempotency of Upgrade
The upgrade operation does do a potentially destructive action in coalescing the 4 volumes to a single volume, but that operation is only happens if the single volume does not have data on it. Once the upgrade is performed the first time, any further upgrade operations will effectively skip that coalescence operation without causing any additional issues. 


## Recovering from a failed upgrade
If the upgrade fails, the suggested recovery path is removing the helm chart and reinstalling, and then running this command to restore the data from the backup:

```
cat cribl_backup.tar| kubectl -n <namespace> exec --stdin <pod name> -- bash -c "cd /opt/cribl/config-volume/; tar xf -"
```

This will restore the data into the "new" volume (which is mounted as /opt/cribl/config-volume). If you want to doublecheck that:

```
kubectl -n <namespace> exec <pod name> -- bash -c "ls -alR /opt/cribl/config-volume"
```


# Caveats/Known Issues
* The pre-2.4 upgrade process creates an initContainer, which will run prior to any instance of the logstream pod. Since the coalescence operation will not overwrite existing data, this is not a functional problem, but depending on your persistent volume setup, may cause pod restarts to take additional time waiting for the release of the volume claims. The only upgrade path that will have this issue is 2.3* -> 2.4.0 - in the next iteration, we'll remove the initContainer from the upgrade path. 
* The pre-2.4 upgrade process does leave the old PersistentVolumes and PersistentVolumeClaims around. This, unfortunately, is necessary for this upgrade path. In follow on versions, these volumes will be removed from the chart.
* [EKS Specific Issues](../../common_docs/EKS_SPECIFICS.md)

# Feedback/Support

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) in the #kubernetes channel.
