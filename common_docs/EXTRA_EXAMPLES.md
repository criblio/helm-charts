## Using envValueFrom<a name="envValueFrom"></a>
_Availability: logstream-workergroup and logstream-master_

The `envValueFrom` option takes a list of maps, just as the `env` attribute does in K8s manifests. The documentation for exposing Downward API data like this is available on this [K8s Doc Page](https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/).

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

## Using extraConfigMapMounts <a name="extraConfigmapMounts"></a>
_Availability: logstream-workergroup and logstream-master_

The `extraConfigmapMounts` option allows you to mount a `ConfigMap` object within a pod. It takes a list of maps to define each `ConfigMap` you wish to mount. It uses a subset of the fields that you'd normally use in a `volumeMount`. Fields:

<dl>
<dt>name</dt>
<dd>The name to use for the volume portion and the volume mount. Recommended, for simplicity, is to use the same name as the ConfigMap itself, but the naming is arbitrary.</dd>
<dt>configMap</dt>
<dd>The name of the ConfigMap to mount.<dd>
<dt>mountPath</dt>
<dd>The path to mount the ConfigMap on. </dd> 
<dt>subPath</dt>
<dd>The subpath to mount – one of the elements in the ConfigMap. Without this, it will treat the ConfigMap as a group of files and mount it as a directory, containing each of the elements as individual files.</dd>
<dt>readOnly</dt>
<dd>Whether to mount the ConfigMap read-only or read/write – default (and recommended) is read-only. </dd>
</dl>

### Example
The example mounts the `job-config` ConfigMap as the directory `/var/tmp/job-config` – all items within the ConfigMap are exposed as files.

```
extraConfigmapMounts:
  - name: job-config
    configMap: job-config
    mountPath: /var/tmp/job-config
    readOnly: true
```

## Using extraSecretMounts <a name="extraSecretMounts"></a>
_Availability: logstream-workergroup and logstream-master_

The `extraSecretMounts` option allows you to mount a K8s [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) object within a pod. It takes a list of maps that define each Secret you wish to mount. It uses a subset of the fields that you'd normally use in a `volumeMount`. Fields:

<dl>
<dt>name</dt>
<dd>The name to use as an identifier for both the volume portion and the volume mount. Recommended, for simplicity, is to use the same name as the secret itself, but the naming is arbitrary.</dd>
<dt>secretName</dt>
<dd>The name of the Secret to mount.</dd>
<dt>mountPath</dt>
<dd>The path to mount the Secret on. </dd> 
<dt>subPath</dt>
<dd>The name of an individual item in the Secret to present on the mount point.</dd>
<dt>readOnly</dt>
<dd>Whether to mount the Secret read-only or read/write – default (and recommended) is read-only. </dd>
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

The `extraVolumeMounts` option allows you to mount multiple volume types within a pod. If you specify an `existingClaim` attribute, it will mount the specified Persistent Volume Claim (PVC) as a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/). If you instead specify a `hostPath` attribute, it will mount that path from the host node into the Pod as a [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) volume. If you include neither, `extraVolumeMounts` will treat the definition as an [emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) mount.

<dl>
<dt>name</dt>
<dd>The name of the ConfigMap to mount.
<dt>existingClaim</dt>
<dd>If this is set, it will attempt to mount the PVC specified in the <code>existingClaim</code> attribute. </dd>
<dt>hostPath</dt>
<dd>The path on the host (the node) to mount into the pod.</dd>
<dt>mountPath</dt>
<dd>The path to mount the volume on. </dd> 
<dt>subPath</dt>
<dd>The subpath to use – this subpath will be created if not already present, and the subpath will be mounted on the <code>mountPath</code>. 
<dt>subPathExpr</dt>
<dd>This performs the same function as <code>subPath</code>, but allows you to define that subpath using environment variables. This is useful on shared storage (like EFS, for example), where you might want each pod to mount a subdirectory that is named after the pod. 
<dt>readOnly</dt>
<dd>Whether to mount the volume read-only or read/write – default is read/write. </dd>


</dl>

### Example
This example mounts two extra directories:
* An `emptyDir`, mounted on /var/lib/testin
* An existing PVC, called `test-volume`, mounted on `/var/tmp/test-volume`

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

## Using extraContainers <a name="extraContainers"></a>
_Availability: logstream-workergroup and logstream-master_

The `extraContainers` option allows you to run one or more sidecar containers along with the main LogStream container. This allows you to implement the standard sidecar pattern with the logstream helm charts. This takes one or more container definitions.

### Example
Here is an simple container definition that uses the fluentd container as a sidecar, also mounting the config-storage volume from the logstream container within the sidecar. 

```
extraContainers:
- name: fluentd
  image: "fluentd"
  volumeMounts:
    - mountPath: /my_mounts/cribl-config
      name: config-storage

```

## Using extraInitContainers <a name="extraInitContainers"></a>
_Availability: logstream-workergroup and logstream-master_

The `extraInitContainers` option allows you to run one or more `initContainer`s before the main LogStream worker container starts up. This can be useful for making OS-level changes to a persistent volume (like `chown` or `chmod` of files or directories), among other things. This takes one or more container definitions.

### Example
Here is an extremely simple container definition that uses the base alpine container image and changes the permissions on the directory `/opt/mypath` to 755.

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

The `securityContext` option allows you to define a user ID and a group ID to run the container processes under. When you do this, the first step the container goes through, prior to starting LogStream, is to `chown` the `/opt/cribl` directory (recursively) to that user/group ID. On the logstream-master chart, it also `chown`s the `/opt/cribl/config-volume` directory tree. It then starts the `entrypoint.sh` script as the specified user.

### Example
This example runs the processes under the user ID of `1020` and the group ID of `30`. 

```
securityContext:
  runAsUser: 1020
  runAsGroup: 30
```

## env <a name="env"></a>
_Availability: logstream-workergroup and logstream-master_

The `env` option allows you to specify additional static environment variables for the container. This takes a set of key-value pairs.

### Example
This example creates two environment variables, `DATA_DIR` and `JOB_ID`.

```
env: 
  DATA_DIR: "/var/tmp/data"
  JOB_ID: "reconciliation"
```

## rbac.extraRules <a name="rbac.extraRules"></a>
_Availability: logstream-workergroup_

The `rbac.extraRules` option allows you to specify additional RBAC rules into the RBAC setup for logstream-workergroup. It does require `rbac.create` to be set to `true`. it takes a list of maps, just like the rules in a Kubernetes role. 

### Example
This example provides access to `deployments`, allowing verbs `get`, `list`, `watch`, `create`, `update`, `patch`, and `delete`, for the API groups `extensions` and `apps`.

```
- apiGroups: ["extensions", "apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
## Using extraInitContainers <a name="extraInitContainers"></a>
_Availability: logstream-workergroup and logstream-master_

The `extraInitContainers` option allows you to run one or more `initContainer`s before the main LogStream worker container starts up. This can be useful for making OS-level changes to a persistent volume (like `chown` or `chmod` of files or directories), among other things. This takes one or more container definitions.

### Example
Here is an extremely simple container definition that uses the base alpine container image and changes the permissions on the directory `/opt/mypath` to 755.

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

The `securityContext` option allows you to define a user ID and a group ID to run the container processes under. When you do this, the first step the container goes through, prior to starting LogStream, is to `chown` the `/opt/cribl` directory (recursively) to that user/group ID. On the logstream-master chart, it also `chown`s the `/opt/cribl/config-volume` directory tree. It then starts the `entrypoint.sh` script as the specified user.

### Example
This example runs the processes under the user ID of `1020` and the group ID of `30`. 

```
securityContext:
  runAsUser: 1020
  runAsGroup: 30
```

## env <a name="env"></a>
_Availability: logstream-workergroup and logstream-master_

The `env` option allows you to specify additional static environment variables for the container. This takes a set of key-value pairs.

### Example
This example creates two environment variables, `DATA_DIR` and `JOB_ID`.

```
env: 
  DATA_DIR: "/var/tmp/data"
  JOB_ID: "reconciliation"
```

## rbac.extraRules <a name="rbac.extraRules"></a>
_Availability: logstream-workergroup_

The `rbac.extraRules` option allows you to specify additional RBAC rules into the RBAC setup for logstream-workergroup. It does require `rbac.create` to be set to `true`. it takes a list of maps, just like the rules in a Kubernetes role. 

### Example
This example provides access to `deployments`, allowing verbs `get`, `list`, `watch`, `create`, `update`, `patch`, and `delete`, for the API groups `extensions` and `apps`.

```
- apiGroups: ["extensions", "apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
