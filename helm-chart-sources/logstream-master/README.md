![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# logstream-master Helm Chart

This Chart deploys a Cribl LogStream master server.

# DISCLAIMER

This chart is a work in progress – it is provided as is.

# Deployment

As built, this chart will deploy a Cribl LogStream master server, consisting of a deployment, two services, and a number of persistent volumes. 

![Deployment Diagram](images/k8s-logstream-master.svg)

Of special note is the fact that two load balanced services are created – the main one (named after the Helm release), which is intended as the primary service interface for users; and the "internal" one (named `<helm-release>-internal`), which is intended for the workergroup-to-master communication.

# <span id="pre-reqs"> Pre-Requisites </span>

## Helm Setup

1. Helm (preferably v3) installed – instructions are [here](https://helm.sh/docs/intro/install/).
1. Cribl helm repo configured. To do this:
	`helm repo add cribl https://criblio.github.io/helm-charts/`

## Persistent Storage

The chart requires persistent storage; it will use your default storage class, or you can override that class (`config.scName`) with the name of a storage class to use. This has been tested primarily using AWS EBS storage, via the CSI EBS driver. The volumes are created as `ReadWriteOnce` claims. For more info on Storage Classes, see the [Kubernetes.IO Storage Classes page](https://kubernetes.io/docs/concepts/storage/storage-classes/).

## AWS-Specific Notes

If you're running on EKS, see the [EKS-Specific Issues](../../common_docs/EKS_SPECIFICS.md) doc for details.


# Values to Override

This section covers the most likely values to override. To see the full scope of values available, run `helm show values cribl/logstream-master`. 

|Key|Default Value (or type)|Description|
|---|----|-------------|
|config.adminPassword|String|The password you want the admin user to have set.|
|config.token|String|The auth key you want to set up for worker access. The LogStream instance is configured as a distributed master server only if this value is set. (This can, of course, also be configured via the LogStream UI.) |
|config.license|String|The license for your LogStream instance. If you do not set this, it will default to the "free" license. You can change this in the LogStream UI as well.|
|config.groups| [] |The group names to configure for the master instance – this will create a mapping for each group, which looks for the tag `<groupname>`, and will create the basic structure of each group's configuration.|
|config.scName|\<default storage class\>|The StorageClass Name for all of the persistent volumes.|
|config.rejectSelfSignedCerts|0|0 – allow self-signed certs; or 1 – deny self-signed certs. |
|config.healthPort|9000|The port to use for health checks (readiness/live).|
|service.ports|[]|<pre>- name: api<br>  port: 9000<br>  protocol: TCP<br>  external: true<br>- name: mastercomm<br>  port: 4200<br>  protocol: TCP<br>  external: false</pre>|The ports to make available both in the Deployment and the Service. Each "map" in the list needs the following values set: <dl><dt>containerPort</dt><dd>the port to be made available</dd><dt>name</dt><dd>a descriptive name of what the port is being used for</dd><dt>protocol</dt><dd>the protocol in use for this port (UDP/TCP)</dd><dt>external</dt><dd>Set to true to be exposed on the external service, or false not to</dd></dl>|
|service.annotations|{}|Annotations for the service component – this is where you'll want to put load-balancer-specific configuration directives.|
|criblImage.tag|2.4.5|The container image tag to pull from. By default, this will use the latest release, but you can also use version tags (like "2.3.2") to pull specific versions of LogStream. |
|consolidate_volumes|boolean|If this value exists, and the `helm` command is `upgrade`, this will use the split volumes that we created in charts before 2.4 and consolidate them down to one config volume. This is a ONE-TIME event.|
|__Extra Configuration Options__|
|[extraVolumeMounts](../../common_docs/EXTRA_EXAMPLES.md#extraVolumeMounts)|{}|Additional volumes to mount in the container.|
|[extraSecretMounts](../../common_docs/EXTRA_EXAMPLES.md#extraSecretMounts)|[]|Pre-existing secrets to mount within the container. |
|[extraConfigmapMounts](../../common_docs/EXTRA_EXAMPLES.md#extraConfigmapMounts)|{}|Pre-existing configmaps to mount within the container. |
|[extraInitContainers](../../common_docs/EXTRA_EXAMPLES.md#extraInitContainers)|{}|Additional containers to run ahead of the primary container in the pod.|
|[securityContext.runAsUser](../../common_docs/EXTRA_EXAMPLES.md#securityContext)|0|User ID to run the container processes under.|
|[securityContext.runAsGroup](../../common_docs/EXTRA_EXAMPLES.md#securityContext)|0|Group ID to run the container processes under.|
|[envValueFrom](../../common_docs/EXTRA_EXAMPLES.md#extraEnvFrom)|{}|Environment variables to be exposed from the Downward API.|
|[env](../../common_docs/EXTRA_EXAMPLES.md#env)|[]|Additional static environment variables.|
|ingress.enable|false|Enable Ingress in front of the external service. Setting this to `true` changes the external service to type `NodePort`, and creates an ingress that connects to it.|
|ingress.annotations|{}|If `ingress.enable` is set to `true`, this is where annotations to configure the specific ingress controller. _*NOTE: Ingress is supported only on Kubernetes 1.19 and later clusters*_. |


# Basic Installation

* To  install the chart with the release name "logstream-master":

  `helm install logstream-master cribl/logstream-master`


* To install the chart using the storage class "ebs-sc"

  `helm install logstream-master cribl/logstream-master --set config.scName='ebs-sc'`
  
# Post-Install/Post-Upgrade

LogStream will not automatically deploy changes to the worker nodes. So you'll need to go into the LogStream UI and [commit and deploy changes](https://docs.cribl.io/docs/deploy-distributed) for all of your worker groups. 


# LogStream Configuration Overrides

The Helm chart, without any values overrides, creates effectively a single-instance deployment of Cribl LogStream, using the standard container image. You can, if you so choose, configure distributed mode, licensing, admin user passwords, etc., all from the logstream UI. However, you can install the chart with value overrides to achieve the same goals.

* Applying a License

  If you have a Standard or Enterprise license, you can add it as an override to your install using the `config.license` parameter:

  `helm install logstream-master cribl/logstream-master --set config.license="<long encoded license string redacted>"`
  
* Running Distributed on a Free License

  If you are not specifying a license, you'll need to go into the LogStream user interface and accept the free license. If you've specified the chart's `config.groups` option, the master will be configured as a distributed master. If you don't, it will be configured as a LogStream single instance. You can change this configuration in LogStream's UI.

* Setting the admin password

  Normally, when you first install LogStream and log into the UI, it forces you to change your password. You can skip that by setting your admin password via the `config.adminPassword` parameter:

  `helm install logstream-master cribl/logstream-master --set config.adminPassword="<new password>"`

* Setting up Worker Groups/Mappings

  As mentioned above, the default is to install a vanilla deployment of LogStream. If you are deploying as a master, you can use the `config.groups` parameter to define the worker groups you want created and mapped. Each group in the list you provide will be created as a worker group, with a mapping rule to look for a tag with the worker group name in it. Here is an example:

  `helm install logstream-master cribl/logstream-master --set config.groups={group1,group2,group3}`

  That command will create three worker groups: `group1`, `group2`, and `group3`, and a mapping rule for each.


# Upgrading from a Pre-2.4.0 Version
**NOTE**: This has changed in the 2.4.5 version.

In LogStream 2.4.0, the introduction of the `$CRIBL_VOLUME_DIR` environment variable simplifies the persistent-storage requirement for logstream-master. Instead of maintaining multiple separate persistent volumes (one each for $CRIBL_HOME/{data,state,local,groups, .git, log}), they can all be consolidated into a single volume. 

In the Helm chart, we handle this via the `helm upgrade` command. If you are upgrading from a pre-2.4 version of the chart, you'll want to set the `consolidate_volumes` value, which will create a new, larger, volume and consolidate the data from the original volumes into it. This is done via an `initContainer` that handles the logistics. When it finishes, and the logstream-master pod comes back up, it will be with a single consolidated volume. 

## WARNING: BACK UP YOUR DATA FIRST

While we've tested this upgrade multiple times, there are always differences in environments that can cause problems. As a result, we recommend that you back up the data before running the upgrade command. This is best done with a combination of kubectl and tar:

```
kubectl exec <pod name> -n <namespace> -- bash -c "cd /opt/cribl; tar cf - {state,data,local,groups}" > cribl_backup.tar
```

This command executes the tar based back up of all four volumes, and outputs it to a local tar file (cribl_backup.tar)

## Running the Upgrade

Helm makes upgrades easy, as you just need to run `helm repo update` to ensure that you have the latest repo updates available, followed by `helm upgrade` to actually upgrade the containers.

For example, if you've installed the helm charts in the `logstream` namespace, named your release `ls-master`, and set up your Helm repo per the [pre-reqs](#pre-reqs) section (i.e., named it "cribl"), run the following:

```
helm repo update
helm upgrade ls-master --set consolidate_volumes=true -n logstream cribl/logstream-master
```

## Upgrade Order of Operations

While there should be no major problems running (e.g.) a 2.4.x master with 2.3.4 workers, this is not recommended. Cribl recommends that you upgrade the master Helm chart first, and then upgrade the workers (see [logstream-workergroup/README.md](/criblio/helm-charts/logstream-worker/README.md) for details). 

### Idempotency of Upgrade

The upgrade operation does do a potentially destructive action in coalescing multiple volumes to a single volume, but that operation is only happens if the target single volume has no data on it. Once the upgrade is performed the first time, any further upgrade operations will effectively skip that coalescence operation, without causing any additional issues. 

## Recovering from a Failed Upgrade

If the upgrade fails, the suggested recovery path is removing the Helm chart and reinstalling, and then running this command to restore the data from the backup:

```
cat cribl_backup.tar| kubectl -n <namespace> exec --stdin <pod name> -- bash -c "cd /opt/cribl/config-volume/; tar xf -"
```

This will restore the data into the "new" volume (which is mounted as `/opt/cribl/config-volume`). If you want to double-check that, run:

```
kubectl -n <namespace> exec <pod name> -- bash -c "ls -alR /opt/cribl/config-volume"
```

# Pre-Loading Configuration

The advent of the `extraConfigmapMounts` and `extraSecretMounts` options provides the ability to "preload" configuration files into the master chart, via ConfigMaps and Secrets that you've created in your Kubernetes environment. However, with Configmaps and Secret Mounts being read-only – both *can* be made writeable, but the K8s docs recommend against it – you can't simply mount them into the configuration tree. They need to be mounted to a location outside of the `/opt/cribl` tree, and then the files must be copied into the tree at startup. This copying can be accomplished using environment variables, as we'll see below. 

## Configuration Locations

The chart creates a single configuration volume claim, `config-storage`, which gets mounted as `/opt/cribl/config-volume`. All Worker Group configuration lives under the `groups` subdirectory. If you have a worker group named `datacenter_a`, its configuration will live in `/opt/cribl/config-volume/groups/datacenter_a`. See the LogStream docs' [Configuration Files](https://docs.cribl.io/docs/configuration-files) section for details on file locations.

## Using Environment Variables to Copy Files

The cribl container's entrypoint.sh file looks for up to 30 environment variables that are assumed to be shell script snippets to be executed before LogStream startup (`CRIBL_BEFORE_START_CMD_[1-30]`). It also looks for up to 30 environment variables that are to be executed after LogStream startup (`CRIBL_AFTER_START_CMD_[1-30]`). The variables do need to be in order, and can not skip a number. (The `entrypoint.sh` script breaks the loop the first time it doesn't find an env var, so if you have `CRIBL_BEFORE_START_CMD_1` skipping to `CRIBL_BEFORE_START_CMD_3`, `CRIBL_BEFORE_START_CMD_3` will not be executed.)

The chart uses this capability for injecting the license and setting up groups. We'll use this same capability to copy our config files into place. If you've provided the `config.license` and `config.groups` (occupying the first two slots), you'll need to start with `CRIBL_BEFORE_START_CMD_3`. In the examples below, we'll start with `CRIBL_BEFORE_START_CMD_3`, assuming that a `config.license` and `config.groups` have been set. 

### Figuring Out Which Variable to Use

The easiest way to figure out which environment variable you need to use is to deploy the chart with all the options you plan to use (i.e., use the `helm install` command with options that you plan to for your deployment). Then check the pod definition for `CRIBL_*` environment variables. For example, if you used the following install command:

```
% helm install lsms -f ../master-values.yaml -n logstream-ht cribl/logstream-master
```

You can now get the pod's name: 

```
% kubectl get pods -n logstream-ht
NAME                                           READY   STATUS    RESTARTS   AGE
lsms-master-659bfccdd6-xsz67                   1/1     Running   0          52m
```

And then you can use `kubectl describe` to get the relevant environment variables:

```
% kubectl describe  pod/lsms-master-659bfccdd6-xsz67 -n logstream-ht  | egrep "CRIBL_.*START"
CRIBL_BEFORE_START_CMD_1:      if [ ! -e $CRIBL_VOLUME_DIR/local/cribl/licenses.yml ]; then mkdir -p $CRIBL_VOLUME_DIR/local/cribl ; cp /var/tmp/config_bits/licenses.yml $CRIBL_VOLUME_DIR/local/cribl/licenses.yml; fi
CRIBL_BEFORE_START_CMD_2:      if [ ! -e $CRIBL_VOLUME_DIR/local/cribl/mappings.yml ]; then mkdir -p $CRIBL_VOLUME_DIR/local/cribl;  cp /var/tmp/config_bits/groups.yml $CRIBL_VOLUME_DIR/local/cribl/groups.yml; cp /var/tmp/config_bits/mappings.yml $CRIBL_VOLUME_DIR/local/cribl/mappings.yml; fi
CRIBL_AFTER_START_CMD_1:       [ ! -f $CRIBL_VOLUME_DIR/users_imported ] && sleep 20 && cp /var/tmp/config_bits/users.json $CRIBL_VOLUME_DIR/local/cribl/auth/users.json && touch $CRIBL_VOLUME_DIR/users_imported
```

From that, you can tell that we already have a `CRIBL_BEFORE_START_CMD_1` and `CRIBL_BEFORE_START_CMD_2`, so our next logical variable should be `CRIBL_BEFORE_START_CMD_3`. 

## Scenario

### The ConfigMap
Let's say we want to preconfigure a collector job in the `group1` worker group. The job will be called `InfrastructureLogs`, and it will read ELB logs from an S3 bucket. First, we'll need a `jobs.yml` file, like this:

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

We'll need this loaded into a `ConfigMap` object, so we'd run kubectl to create a `ConfigMap` from the directory where our `jobs.yml` file resides:

`kubectl create configmap job-config --from-file <containing directory> -n <deployment namespace>`

So if that file is in a directory called `./config-dir`, and we're deploying the master chart into the `logstream` namespace, we'd create it like this:

`kubectl create configmap job-config --from-file ./config-dir -n logstream`

### extraConfigmapMounts Config

In our `values.yaml` file, we need to specify the ConfigMap and where to mount it:

```
extraConfigmapMounts:
  - name: job-config
    configMap: job-config
    mountPath: /var/tmp/job-config
```	

This example will mount the files in the ConfigMap in the /var/tmp/job-config directory in the pod. 

### Copying the Config Files

You could simply define, in the `values.yaml` file (or via `--set`):

```
env:
  CRIBL_BEFORE_START_CMD_3: "cp /var/tmp/job-config /opt/cribl/config-volume/groups/group1/local/cribl/jobs.yml"
```

However, there are two potential problems with that:
1. There is no guarantee that the destination directory tree will be there. (The first time a pod spins up, it won't be.)
2. If the pod has crashed and spun up anew, blindly copying will overwrite any changes previously made. This is rarely desirable behavior.

#### File Copying Pattern

Since we may want to copy multiple configuration files in one shot, it makes sense to use some sort of "flag file" to ensure that we copy the files only once. The script snippet to copy the `jobs.yaml` file looks like this, formatted for readability:

```
FLAG_FILE=/opt/cribl/config-volume/job-flag
if [ ! -e $FLAG_FILE ]; then
  mkdir -p /opt/cribl/config-volume/groups/group1/local/cribl # ensure the directory tree exists
  cp /var/tmp/job-config/jobs.yml /opt/cribl/config-volume/groups/group1/local/cribl # copy the file
  touch $FLAG_FILE
fi
```

This looks to see if the file `/opt/cribl/config-volume/job-flag` exists, and if it doesn't, creates the directory tree, copies the config file(s), and then creates the job flag file. However, we need to format it a little differently to easily encompass it in the `env` variable:

```
env: 
  CRIBL_BEFORE_START_CMD_3: "FLAG_FILE=/opt/cribl/config-volume/job-flag; if [ ! -e $FLAG_FILE ]; then mkdir -p /opt/cribl/config-volume/groups/group1/local/cribl; cp /var/tmp/job-config/jobs.yml /opt/cribl/config-volume/groups/group1/local/cribl; touch $FLAG_FILE; fi"
```

Once you run `helm install` with this in the `values.yaml` file, you can do `kubectl exec` on the pod to execute a shell:

`kubectl exec -it <pod name> -- bash`

...and then look at `/opt/cribl/config-volume/groups/group1/local/cribl/jobs.yml` to verify that it is in place. 


# Caveats/Known Issues

* The pre-2.4 upgrade process creates an `initContainer`, which will run prior to any instance of the LogStream pod. Since the coalescence operation will not overwrite existing data, this is not a functional problem. But depending on your persistent-volume setup, it might cause pod restarts to take additional time waiting for the release of the volume claims. The only upgrade path that will have this issue is 2.3* -> 2.4.0. In the next iteration, we'll remove the `initContainer` from the upgrade path. 

* The pre-2.4 upgrade process does leave the old `PersistentVolumes` and `PersistentVolumeClaims` around. This is, unfortunately, necessary for this upgrade path. In follow-on versions, these volumes will be removed from the chart.

* [EKS-Specific Issues](../../common_docs/EKS_SPECIFICS.md).

# Feedback/Support

If you use this Helm chart, we'd love to hear any feedback you might have. Join us on our [Slack Community](https://cribl.io/community) and navigate to the `#kubernetes` channel.
