## Using envValueFrom<a name="envValueFrom"></a>
_Availability: logstream-workergroup and logstream-master_

The envValueFrom option takes a list of maps, just as the env attribute does in K8s manifests. The documentation for exposing Downward API data like this is available at the [K8s Doc Page](https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/).

### Example

This example exposes the Pod Name as the environment variable `PODNAME`, and the name of the node it's running on as the environment variable `NODENAME`.

```
envValueFrom:
- name: PODNAME
  valueFrom: 
    fieldRef:
      fieldPath: metadata.name
- name: NODENAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
```

## Using extraConfigmapMounts <a name="extraConfigmapMounts"></a>
_Availability: logstream-workergroup and logstream-master_

The extraConfigmapMounts option allows you to mount a configMap object within a pod. It takes a list of maps to define each configMap you wish to mount. It uses a subset of the fields that you'd normally use in a volumeMount. Fields:

<dl>
<dt>name</dt>
<dd>The name to use for the volume portion and the volume mount. Recommended for simplicity is to use the same name as the configMap itself, but it can be arbitrary.</dd>
<dt>configMap</dt>
<dd>the name of the configMap to mount.<dd>
<dt>mountPath</dt>
<dd>The path to mount the ConfigMap on. </dd> 
<dt>subPath</dt>
<dd>The subpath to mount - one of the elements in the configMap. Without this, it will treat the configMap as a group of files and mount it as a directory, containing each of the elements as individual files</dd>
<dt>readOnly</dt>
<dd>Whether to mount the configMap read only or read write - Default (and recommended) is read only. </dd>
</dl>

### Example
The example mounts the job-config configMap as the directory /var/tmp/job-config - all items within the configMap are exposed as files.

```
extraConfigmapMounts:
  - name: job-config
    configMap: job-config
    mountPath: /var/tmp/job-config
    readOnly: true
```


## Using extraSecretMounts <a name="extraSecretMounts"></a>
_Availability: logstream-workergroup and logstream-master_

The extraSecretMounts option allows you to mount a k8s [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) object within a pod. It takes a list of maps that define each Secret you wish to mount. It uses a subset of the fields that you'd normally use in a volumeMount. Fields:


<dl>
<dt>name</dt>
<dd>The name to use as an identifier for both the volume portion and the volume mount. Recommended for simplicity is to use the same name as the secret itself, but it can be arbitrary.</dd>
<dt>secretName</dt>
<dd>The name of the Secret to mount.</dd>
<dt>mountPath</dt>
<dd>The path to mount the secret on. </dd> 
<dt>subPath</dt>
<dd>the name of an individual item in the secret to present on the mount point</dd>
<dt>readOnly</dt>
<dd>Whether to mount the secret read only or read write - Default (and recommended) is read only. </dd>
</dl>

### Example
The example mounts a single item `item1` from the secret.

```
extraSecretMounts:
  - name: test-secret
    secretName: test-secret
    mountPath: /var/tmp/test-secret
    subPath: item1
    readOnly: true
```

## Using extraVolumeMounts <a name="extraVolumeMounts"></a>
_Availability: logstream-workergroup and logstream-master_

The extraVolumeMounts option allows you to mount multiple volume types within a pod. If you specify an existingClaim attribute, it will mount the specified Persistent Volume Claim (PVC) as a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/). If you, instead, specify a hostPath attribute, it will mount that path from the host node as a [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) volume into the Pod. If you include neither, it will treat the definition as an [emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) mount.

<dl>
<dt>name</dt>
<dd>The name of the ConfigMap to mount.
<dt>existingClaim</dt>
<dd>If this is set, it will attempt to mount the pvc specified in the existingClaim attribute. </dd>
<dt>hostPath</dt>
<dd>The path on the host (the node) to mount into the pod</dd>
<dt>mountPath</dt>
<dd>The path to mount the volume on. </dd> 
<dt>subPath</dt>
<dd>The subpath to use - this subpath will be created if not already present, and the subpath will be mounted on the mountPath. 
<dt>subPathExpr</dt>
<dd>this performs the same function as subPath, but allows you to define that subpath using environment variables. This is useful on shared storage (like EFS, for example), where you might want each pod to mount a subdirectory that is named after the pod. 
<dt>readOnly</dt>
<dd>Whether to mount the volume read only or read write - Default is read write. </dd>


</dl>

### Example
This example mounts two extra directories:
* an emptyDir, mounted on /var/lib/testin
* an existing PVC, called `test-volume`, mounted on /var/tmp/test-volume

```
extraVolumeMounts:
- name: testing
  mountPath: /var/lib/testing
  readOnly: false
- name: test-volume
  mountPath: /var/tmp/test-volume
  existingClaim: test-volume
  readOnly: false
```

## Using extraInitContainers <a name="extraInitContainers"></a>
_Availability: logstream-workergroup and logstream-master_

The extraInitContainers option allows you to run one or more initContainers prior to the main logstream worker container starting up. This can be useful for making OS level changes to a persistent volume (like chown or chmod of files or directories), among other things. This takes one or more container definitions.

### Example
This example is an extremely simple container definition that uses the base alpine container image that changes the permissions on the directory `/opt/mypath` to 755.

```
extraInitContainers:
- name: testing
  image: "alpine:latest"
  command: ["/bin/ash", "-c"]
  args:
    - chmod 755 /opt/mypath
```

## Using securityContext <a name="securityContext"></a>
_Availability: logstream-workergroup and logstream-master_

The securityContext option allows you to define a user id and a group id to run the container processes under. When you do this, the first step the container goes through, prior to starting logstream, is to chown the /opt/cribl directory recursively to that user/group id. On the logstream-master chart, it also chowns the /opt/cribl/config-volume directory tree. It then starts the entrypoint.sh script as the specified user.

### Example
This example runs the processes under the userid of 1020 and the group id of 30. 

```
securityContext:
  runAsUser: 1020
  runAsGroup: 30
```

## env <a name="env"></a>
_Availability: logstream-workergroup and logstream-master_

The env option allows you to specify additional static environment variables for the container. This takes a set of key value pairs.

### Example
This example creates two environment variables, `DATA_DIR` and `JOB_ID`

```
env: 
  DATA_DIR: "/var/tmp/data"
  JOB_ID: "reconciliation"
```

## rbac.extraRules <a name="rbac.extraRules"></a>
_Availability: logstream-workergroup_

The rbac.extraRules option allows you to specify additional RBAC rules into the RBAC setup for logstream-workergroup. It does require rbac.create to be set to `true`. it takes a list of maps, just like the rules in a Kubernetes role. 

### Example
This example provides access to "deployments", allowing verbs `get`, `list`, `watch`, `create`, `update`, `patch`, and `delete`, for the API groups `extensions` and `apps`.

```
- apiGroups: ["extensions", "apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```