# EKS-Specific Info and Errata

At Cribl, we develop our charts on our AWS EKS environments, but we use annotations, etc. for implementation-specific configurations. In this document we share our experience with our charts on the EKS platform. 

## Service Annotations

For the services in the Helm charts, you can make many annotations for the load balancer-type when running on EKS. Internally, we usually use the annotations for logging to S3, like this:

```
    service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "5"
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: "<bucket name>"
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: "ELB"
```

For a fairly exhaustive lists of annotations you can use with AWS's Elastic Load Balancers, see the [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/) page.

## Ingress Annotations

The AWS Load Balancer controller has a wide array of annotations that you can use to configure the ingress. Refer to the [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/guide/ingress/annotations.md#actions) GitHub page for details. Internally, for testing purposes, we used this example:

```
ingress:
  enable: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
```

This example sets the ingress's class to `alb`, which tells the controller to use an ALB. It tells it to listen on port 80, and it sets the "scheme" to internet-facing, which provisions an ALB with a routable internet address.

## AWS IAM Role for Worker Group

To allow Pods to use IAM Roles, you first need to configure an IAM OIDC Provider and IAM Role. You can read more about the required configs on the AWS Docs site: [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

Once you configure the OIDC Provider and IAM Role, add the following to your `values.yaml` file (update the placeholders with the appropriate values):

```
rbac:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::01234567890:role/your-iam-role-name-for-cribl-stream-worker-group
```

## Known EKS Problems

### Persistent Storage Issues

With the logstream-leader chart, the default persistent storage (and the CSI driver) use EBS for persistent volumes. EBS volumes are availability-zone–specific. If the EKS cluster is using a single node group that spans availability zones, and a node dies, there's no guarantee that there will be another node on which to schedule it in that availability zone. When that happens, the master pod will sit in an error state until there is a node in that availability zone that can access the EBS volume.

#### Avoidance

As a solution, use the availability-zone–aware node groups with autoscaling. Our internal clusters are set up with nodegroups that have a minimum of 1 node and a maximum of 4 nodes, and each nodegroup is in a specific AZ. The `eksctl` docs pages detail the way to deal with this problem – see [https://eksctl.io/usage/autoscaling/#zone-aware-auto-scaling](https://eksctl.io/usage/autoscaling/#zone-aware-auto-scaling). 

### EKS Fargate Resource Settings

The CPU limits must not exceed the requests, otherwise the Pod will fail to initialize with an error. Additionally, make sure the requested CPU and memory configuration are valid for the Fargate platform. The [supported values for CPU and Memory resources](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html) are available on the AWS documentation.

> setting cgroup config for procHooks process caused: failed to write "200000": write /sys/fs/cgroup/cpu,cpuacct/kubepods/burstable/.../cpu.cfs_quota_us: invalid argument: unknown

A sample validated resource config that provisions 4 vCPU and 8 GB of RAM on EKS Fargate:

```yaml
resources:
  limits:
    cpu: 4
    memory: 8192Mi
  requests:
    cpu: 4
    memory: 8192Mi
```
