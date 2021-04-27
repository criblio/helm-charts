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

If you're running on EKS, see the [EKS Specific Issues](../../common_docs/EKS_SPECIFICS.md) doc for details.


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

# Pre-Loading Configuration

The advent of the extraConfigmapMounts and extraSecretMounts options provide the ability to "preload" configuration files into the master chart. However, with Configmap and Secret Mounts being read only (both *can* be made writeable, but the k8s docs recommend against it), you can't simply mount them into the configuration tree. They need to be mounted to a location outside of the /opt/cribl tree, and then the files be copied into the tree at startup. 

## Configuration Locations

The chart creates a single configuration volume claim, "config-storage", which gets mounted as `/opt/cribl/config-volume`. All Worker Group configuration lives under the `groups` subdirectory. If you have a worker group named "datacenter_a", it's configuration will live in `/opt/cribl/config-volume/groups/datacenter_a`.

## Using Environment Variables to Copy Files

The cribl container's entrypoint.sh file looks for up to 30 environment variables that are assumed to be shell script snippets to be executed before LogStream startup (CRIBL\_BEFORE\_START\_CMD\_[1-30]), and up to 30 environment variables that are to be executed after LogStream startup (CRIBL\_AFTER\_START\_CMD\_[1-30]. The variables do need to be in order, and can not skip a number (the entrypoint.sh script breaks the loop the first time it doesn't find an env var, so if you have CRIBL\_BEFORE\_START\_CMD\_1 and CRIBL\_BEFORE\_START\_CMD\_3, CRIBL\_BEFORE\_START\_CMD\_3 will not be executed.

The chart uses this capability for injecting the license and setting up groups. We'll use this same capability to copy our config files into place. If you've provided the config.license and config.groups, you'll need to start with CRIBL\_BEFORE\_START\_CMD\_3. 

## Scenario

### The ConfigMap
Let's say we want to pre-configure a collector job in the `group1` worker group called "InfrastructureLogs" that reads ELB logs from an S3 bucket. First, we'll need a jobs.yml file, like this:

```
InfrastructureLogs:
  type: collection
  ttl: 4h
  removeFields: []
  resumeOnBoot: false
  schedule: {}
  collector:
    conf:
      signatureVersion: v4
      enableAssumeRole: true
      recurse: true
      maxBatchSize: 10
      bucket: <my infrastructure logs bucket>
      path: /ELB/AWSLogs/${aws_acct_id}/elasticloadbalancing/${aws_region}/${_time:%Y}/${_time:%m}/${_time:%d}/
      region: us-west-2
      assumeRoleArn: arn:aws:iam::<accountid>:role/LogReadAssume
    destructive: false
    type: s3
  input:
    type: collection
    staleChannelFlushMs: 10000
    sendToRoutes: false
    preprocess:
      disabled: true
    throttleRatePerSec: "0"
    breakerRulesets:
      - AWS Ruleset
    pipeline: devnull
    output: devnull
```

We'll need this loaded into a configmap object, so we'd run kubectl to create a configmap from the directory our jobs.yml file is in:

`kubectl create configmap job-config --from-file <containing directory> -n <deployment namespace>`

so if that file is in a directory called ./config-dir, and we're deploying the master chart into the `logstream` namespace, we'd create it like this:

`kubectl create configmap job-config --from-file ./config-dir -n logstream`

### extraConfigmapMounts Config

in our values.yaml file, we need to specify the ConfigMap and where to mount it:

```
extraConfigmapMounts:
  - name: job-config
    configMap: job-config
    mountPath: /var/tmp/job-config
```	

This example will mount the files in the ConfigMap in the /var/tmp/job-config directory in the pod. 

### Copying the Config Files

While you could simply define, in the values file (or via --set):

```
env:
  CRIBL_BEFORE_START_CMD_3: "cp /var/tmp/job-config /opt/cribl/config-volume/groups/group1/local/cribl/jobs.yml"
```

However, there are two potential problems with that:
1. There is no guarantee that the destination directory tree will be there (the first time a pod spins up, it won't be).
2. Just blindly copying will overwrite any changes that have been made if the pod crashes and is spun up anew. This is rarely desirable behavior. 

#### File Copying Pattern

Since we may want to copy multiple configuration files in one shot, it makes sense to use some sort of "flag file" to ensure that we only copy the files once. The script snippet to copy the jobs.yaml file, formatted for readability, looks like this:

```
FLAG_FILE=/opt/cribl/config-volume/job-flag
if [ ! -e $FLAG_FILE ]; then
  mkdir -p /opt/cribl/config-volume/groups/group1/local/cribl # ensure the directory tree exists
  cp /var/tmp/job-config/jobs.yml /opt/cribl/config-volume/groups/group1/local/cribl # copy the file
  touch $FLAG_FILE
fi
```

This looks to see if the file `/opt/cribl/config-volume/job-flag` exists, and if it doesn't, creates the directory tree, copies the config file(s), and then creates the job flag file. However, we need to format it a little differently to encompass it in the env variable easily:

```
env: 
  CRIBL_BEFORE_START_CMD_3: "FLAG_FILE=/opt/cribl/config-volume/job-flag; if [ ! -e $FLAG_FILE ]; then mkdir -p /opt/cribl/config-volume/groups/group1/local/cribl; cp /var/tmp/job-config/jobs.yml /opt/cribl/config-volume/groups/group1/local/cribl; touch $FLAG_FILE; fi"
```

Once run helm install with this in the values file, you can do `kubectl exec` on the pod to execute a shell:

`kubectl exec -it <pod name> -- bash`

and then look at /opt/cribl/config-volume/groups/group1/local/cribl/jobs.yml to verify that it's in place. 


# Caveats/Known Issues
* The pre-2.4 upgrade process creates an initContainer, which will run prior to any instance of the logstream pod. Since the coalescence operation will not overwrite existing data, this is not a functional problem, but depending on your persistent volume setup, may cause pod restarts to take additional time waiting for the release of the volume claims. The only upgrade path that will have this issue is 2.3* -> 2.4.0 - in the next iteration, we'll remove the initContainer from the upgrade path. 
* The pre-2.4 upgrade process does leave the old PersistentVolumes and PersistentVolumeClaims around. This, unfortunately, is necessary for this upgrade path. In follow on versions, these volumes will be removed from the chart.
* [EKS Specific Issues](../../common_docs/EKS_SPECIFICS.md)

# Feedback/Support

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) in the #kubernetes channel.
