![Cribl Logo](../../images/Cribl_Logo_Color_TM.png)

# Edge Helm Chart

This chart deploys a Cribl Edge DaemonSet in a Kubernetes Cluster.

# Deployment

As built, this chart will deploy a DaemonSet on all Nodes in a K8s cluster, Service Account, Cluster Role, Cluster Role Binding, and Secret for setting the Cribl Leader configuration.

When deploying this chart, you must change the Fleet API host from binding on `127.0.0.1` to `0.0.0.0`. If you do not, health checks will fail and the Pods will be continually replaced.

**Note**: This chart does **not** deploy a Cribl Leader node!

# Prerequisites

1. Helm v3 installed – instructions are [here](https://helm.sh/docs/intro/install/).
2. Cribl helm repo configured. To do this:
    `helm repo add cribl https://criblio.github.io/helm-charts/`

# Known Issues

* This chart is not deployable on EKS Fargate. See [AWS Fargate considerations](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html#fargate-considerations) for more information.

# More Info

For additional documentation about this chart, see the [Cribl Docs](https://docs.cribl.io/edge/deploy-running-kubernetes) page.

# Support/Feedback

If you use this helm chart, we'd love to hear any feedback you might have on this chart. Join us on our [Slack Community](https://cribl.io/community) and navigate to the `#containers` channel.

# Values to Override

This section covers the most likely values to override. To see the full scope of values available, run `helm show values cribl/edge`. 

| Key                                                                            | Default Value     | Description                                                                         |
|--------------------------------------------------------------------------------|-------------------|-------------------------------------------------------------------------------------|
| image.repository                                                               | `cribl/cribl`     | Docker image repository to pull images                                              |
| image.pullPolicy                                                               | `Always`          | When will the Node pull the image                                                   |
| image.tag                                                                      | `4.7.1`           | The Version of Cribl to deploy                                                      |
| imagePullSecrets                                                               | `[]`              | Credentials to pull container images                                                |
| nameOverride                                                                   |                   | Overrides the chart name                                                            |
| fullNameOverride                                                               |                   | Overrides the Helm deployment name                                                  |
| [extraEnv](../../common_docs/EXTRA_EXAMPLES.md#env)                            | `[]`              | Additional Static Environment Variables.                                            |
| [extraEnvFrom](../../common_docs/EXTRA_EXAMPLES.md#extraEnvFrom)               | `[]`              | Environment variables to be exposed from the Downward API.                          |
| [extraConfigMaps](../../common_docs/EXTRA_EXAMPLES.md#extraConfigmapMounts)    | `[]`              | Pre-existing configmaps to mount within the container.                              |
| [extraSecretMounts](../../common_docs/EXTRA_EXAMPLES.md#extraSecretMounts)     | `[]`              | Pre-existing secrets to mount within the container.                                 |
| [extraVolumeMounts](../../common_docs/EXTRA_EXAMPLES.md#extraVolumeMounts)     | see `values.yaml` | Additional Volumes to mount in the container.                                       |
| [extraContainers](../../common_docs/EXTRA_EXAMPLES.md#extraContainers)         | `{}`              | Additional containers to run as sidecars of the primary container in the pod.       |
| [extraInitContainers](../../common_docs/EXTRA_EXAMPLES.md#extraInitContainers) | `{}`              | Additional containers to run ahead of the primary container in the pod.             |
| cribl.home                                                                     | `/opt/cribl`      | default Cribl directory                                                             |
| cribl.existingSecretForLeader                                                  |                   | Set if using an existing secret for the leader node                                 |
| cribl.leader                                                                   |                   | the CRIBL_DIST_LEADER_URL to configure                                              |
| cribl.existingSecretForConfig                                                  |                   | existing bootstrap config                                                           |
| cribl.config                                                                   |                   | bootstrap config                                                                    |
| cribl.readinessProbe                                                           | see `values.yaml` | readiness probe config                                                              |
| cribl.livenessProbe                                                            | see `values.yaml` | liveness probe config                                                               |
| serviceAccount.create                                                          | `true`            | Specifies whether a service account should be created                               |
| serviceAccount.annotations                                                     | `{}`              | Annotations to add to the service account                                           |
| serviceAccount.name                                                            |                   | override the default generated service account name                                 |
| serviceAccount.automountServiceAccountToken                                    | `true`            | whether the service account token should be automounted into the container          |
| rbac.create                                                                    | `true`            | Specifies whether a role should be created                                          |
| rbac.annotations                                                               | `{}`              | Annotations to add to the role                                                      |
| rbac.extraRules                                                                | `[]`              | Additional rules to add to the role                                                 |
| podAnnotations                                                                 | `{}`              | Annotations to add to the pod                                                       |
| podSecurityContext                                                             | `{}`              | Security context for the Pod                                                        |
| securityContext                                                                | `{}`              | Security context for the Cribl container                                            |
| service.enable                                                                 | `false`           | Specifies whether a service should be created                                       |
| service.type                                                                   | `ClusterIP`       | The type of service deployed                                                        |
| service.externalTrafficPolicy                                                  | `Cluster`         | IP address visibility                                                               |
| service.annotations                                                            | `{}`              | Annotations to add to the service                                                   |
| service.ports                                                                  | see `values.yaml` | Ports configured for the service                                                    |
| ingress.enable                                                                 | `false`           | Specifies if an ingress should be created                                           |
| ingress.className                                                              |                   | The ingress class name                                                              |
| ingress.annotations                                                            | `{}`              | Annotations to be added to all ingresses                                            |
| ingress.ingress                                                                | see `values.yaml` | Ingress resources to be created                                                     |
| resources.limits                                                               | see `values.yaml` | Limits for the Edge Pod                                                             |
| resources.requests                                                             | see `values.yaml` | Reserved resources for the Edge Pod                                                 |
| nodeSelector                                                                   | `{}`              | Node selection for Pod deployment                                                   |
| tolerations                                                                    | see `values.yaml` | Node tolerations/taints allowed for deploying the Edge Pods                         |
| extraObjects                                                                   | `{}`              | Ability to add custom Kubernetes objects into this deployment as part of this chart |