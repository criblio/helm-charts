![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# Outpost Helm Chart

This chart deploys Cribl Outpost.

# Deployment

This chart will deploy Cribl Outpost, consisting of a deployment, a service, and a secret used for configuration.

This chart does **not** deploy a Leader node – it depends on that node's already being present.

# Prerequisites

1. Helm (preferably v3) installed – instructions are [here](https://helm.sh/docs/intro/install/).
2. Cribl helm repo configured. To do this:
	`helm repo add cribl https://criblio.github.io/helm-charts/`

# Values to Override

This section covers the most likely values to override. To see the full scope of values available, run `helm show values cribl/outpost`.

|Key|Default Value|Description|
|---|-------------|-----------|
|cribl.leader||The Cribl Leader URL to connect to (format: `tcp://authToken@host:port/?group=groupname&tag=tagname`). **Required if `cribl.existingSecretForLeader` is not set.**|
|cribl.existingSecretForLeader||Name of existing secret containing `CRIBL_DIST_LEADER_URL`. If set, overrides `cribl.leader`.|
|cribl.listener|tcp://0.0.0.0:4200|The Cribl Outpost listener URL for the internal interface (format: `tcp://token@host:port` or `tls://token@host:port?tls.certPath=/path&tls.keyPath=/path`). **Optional.**|
|cribl.listenerTLS.existingSecret||Name of existing Kubernetes secret containing `tls.crt` and `tls.key` for the listener interface. **Optional.**|
|cribl.listenerTLS.mountPath|"/etc/cribl/certs"|Path where TLS certificates will be mounted in the container. **Optional.**|
|cribl.config||Bootstrap configuration (YAML format) to be passed as `CRIBL_BOOTSTRAP` environment variable.|
|cribl.existingSecretForConfig||Name of existing secret containing `CRIBL_BOOTSTRAP`. If set, overrides `cribl.config`.|
|cribl.home|"/opt/cribl"|The CRIBL_HOME directory path.|
|cribl.rejectSelfSignedCerts|0| One of: `0` – allow self-signed certs; or `1` – deny self-signed certs. |
|cribl.probes|true|Enables (true) or disables (false) the liveness and readiness probes.|
|cribl.livenessProbe|see `values.yaml`|[livenessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request) configuration|
|cribl.readinessProbe|see `values.yaml`|[readinessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes) configuration|
|service.enable|true|Enable creating Service resources.|
|service.type|ClusterIP|The type of service to create for the outpost|
|service.ports|<pre>- name: api<br>  port: 9000<br>  protocol: TCP<br>- name: distmgt<br>  port: 4200<br>  protocol: TCP</pre>|The ports to make available both in the Deployment and the Service. Each "map" in the list needs the following values set: <dl><dt>name</dt><dd>A descriptive name of what the port is being used for.</dd><dt>port</dt><dd>The port to make available.</dd><dt>protocol</dt><dd>The protocol in use for this port (UDP/TCP).</dd></dl>|
|service.annotations|{}|Annotations for the service component.|
|replicaCount|1|Number of Outpost replicas to run.|
|resources.limits.cpu|2000m|The maximum amount of CPU to allocate to each Outpost instance.|
|resources.limits.memory|4096Mi|The maximum amount of memory to allocate to each Outpost instance.|
|resources.requests.cpu|500m|The minimum guaranteed CPU to allocate to each Outpost instance.|
|resources.requests.memory|1024Mi|The minimum guaranteed memory to allocate to each Outpost instance.|
|criblImage.repository|cribl/cribl|The image repository to pull from.|
|criblImage.tag|4.14.1|The image tag to pull.|
|criblImage.pullPolicy|IfNotPresent|The image pull policy.|
|serviceAccount.create|true|Whether to create a service account for the outpost.|
|rbac.create|true|Whether to create RBAC resources (Role and RoleBinding).|
|rbac.roleRules|see `values.yaml`|Namespace-scoped RBAC rules (get pods, get deployments).|
|rbac.extraRoleRules|[]|Additional namespace-scoped RBAC rules.|
|rbac.annotations|{}|Annotations to add to RBAC resources.|
|rbac.name||Custom name for RBAC resources (defaults to generated name).|
|imagePullSecrets|[]|Image pull secrets for private registries.|
|nodeSelector|{}|Node selector for pod assignment.|
|tolerations|[]|Tolerations for pod assignment.|
|affinity|{}|Affinity rules for pod assignment.|
|env|{}|Environment variables for the Cribl Outpost container.|
|extraEnv|{}|Extra environment variables (with template support).|
|extraEnvFrom|[]|Extra environment variables from ConfigMaps or Secrets.|
|extraLabels|{}|Extra labels to apply to all resources.|
|extraObjects|{}|Extra Kubernetes objects to deploy.|
|extraVolumeMounts|{}|Extra volume mounts to add to the pod.|
|extraConfigMaps|[]|Extra ConfigMaps to mount.|
|extraSecretMounts|[]|Extra Secrets to mount.|

# Installation

```bash
helm repo add cribl https://criblio.github.io/helm-charts/
helm install outpost cribl/outpost \
  --set cribl.leader="tcp://<your-auth-token>@<your-leader-host>:4200/?group=outpost&tag=outpost"
```

# Configuration

## Leader Connection

The Outpost connects to a Cribl Leader using the `cribl.leader` value, which should be formatted as a connection URL:

```text
<protocol>://<token>@<host>:<port>/?group=<group>&tag=<tag>
```

**Example:**

```text
tcp://criblleader@logstream-leader-internal:4200/?group=outpost&tag=outpost
```

**Protocol Options:**

- `tcp`: Standard TCP connection (default)
- `tls`: TLS-encrypted connection (include TLS-specific query parameters as needed)

**TLS Configuration:**

To use TLS, construct the leader URL with `tls://` protocol and include TLS parameters:

```text
tls://token@host:port/?group=mygroup&tag=mytag&tls.rejectUnauthorized=1&tls.caPath=/path/to/ca.pem
```

**Using Existing Secret:**

Instead of specifying `cribl.leader`, you can reference an existing secret:

```bash
helm install outpost cribl/outpost \
  --set cribl.existingSecretForLeader=my-leader-secret
```

The secret must contain a key `CRIBL_DIST_LEADER_URL` with the connection URL.

## Bootstrap Configuration

You can provide bootstrap configuration (in YAML format) via `cribl.config`:

```yaml
cribl:
  config: |
    cribl/local.yml:
      foo: bar
      baz: qux
```

Or use an existing secret with `cribl.existingSecretForConfig`.

## Listener Interface Configuration

The Outpost can expose an internal listener interface (similar to the Leader's listener interface) for receiving connections from other Cribl components. This is configured using the `CRIBL_OUTPOST_LISTENER_URL` environment variable.

### Basic Configuration

Set the `cribl.listener` value with the full listener URL:

```yaml
cribl:
  listener: "tcp://mytoken@0.0.0.0:4200"
```

### TLS Configuration

For secure connections using TLS, you need to:

1. Set the `listener` with the `tls://` protocol and paths to the certificate and key
2. Provide the TLS certificate and key via an existing Kubernetes secret

Create a TLS secret with your certificate and key:

```bash
kubectl create secret tls outpost-listener-tls \
  --cert=path/to/server.crt \
  --key=path/to/server.key
```

Then configure Outpost to use it:

```yaml
cribl:
  listener: "tls://mytoken@0.0.0.0:4200?tls.certPath=/etc/cribl/certs/tls.crt&tls.keyPath=/etc/cribl/certs/tls.key"
  listenerTLS:
    existingSecret: outpost-listener-tls
    mountPath: /etc/cribl/certs  # Default, can be omitted
```

**Note:** The paths in `listener` (tls.certPath and tls.keyPath) must match the mount path and the standard Kubernetes TLS secret key names (`tls.crt` and `tls.key`).

### Example Deployments

**Basic TCP Listener:**

```bash
helm install my-outpost cribl/outpost \
  --set cribl.leader="tcp://leadertoken@logstream-leader-internal:4200/?group=outpost&tag=outpost" \
  --set cribl.listener="tcp://outposttoken@0.0.0.0:4200"
```

**TLS Listener:**

```bash
# First create the TLS secret
kubectl create secret tls outpost-listener-tls \
  --cert=server.crt \
  --key=server.key

# Then deploy the chart
helm install my-outpost cribl/outpost \
  --set cribl.leader="tcp://leadertoken@logstream-leader-internal:4200/?group=outpost&tag=outpost" \
  --set cribl.listener="tls://outposttoken@0.0.0.0:4200?tls.certPath=/etc/cribl/certs/tls.crt&tls.keyPath=/etc/cribl/certs/tls.key" \
  --set cribl.listenerTLS.existingSecret="outpost-listener-tls"
```

# Service Ports

The Outpost exposes two ports by default:

- **9000**: API port for health checks and management
- **4200**: Leader communication port

# Examples

## Basic Deployment

```bash
helm install my-outpost cribl/outpost \
  --set cribl.leader="tcp://mytoken123@logstream-leader-internal:4200/?group=production-outpost&tag=production-outpost"
```

## With TLS Enabled

```bash
helm install my-outpost cribl/outpost \
  --set cribl.leader="tls://mytoken123@logstream-leader-internal:4200/?group=production-outpost&tag=production-outpost&tls.rejectUnauthorized=1"
```

## With Multiple Replicas

```bash
helm install my-outpost cribl/outpost \
  --set cribl.leader="tcp://mytoken123@logstream-leader-internal:4200/?group=production-outpost&tag=production-outpost" \
  --set replicaCount=3
```

## Using Existing Secret

First, create a secret with the leader URL:

```bash
kubectl create secret generic my-leader-secret \
  --from-literal=CRIBL_DIST_LEADER_URL="tcp://mytoken@leader:4200/?group=outpost&tag=outpost"
```

Then install the chart referencing that secret:

```bash
helm install my-outpost cribl/outpost \
  --set cribl.existingSecretForLeader=my-leader-secret
```

# Support

For questions or issues, please refer to the [Cribl documentation](https://docs.cribl.io/) or contact Cribl support.
