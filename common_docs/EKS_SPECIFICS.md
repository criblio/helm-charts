# EKS Specific Info and Errata

At Cribl, we develop our charts on our AWS EKS environments, but try to make sure that any implementation-specific configuration is done in annotations, etc. This document is intended to share our experience with our charts on the EKS platform. 

## Service Annotations

For the services in the Helm charts, many annotations can be made for the load balancer-type when running on EKS. Internally, we usually use the annotations for logging to S3, like this:

```
    service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "5"
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: "<bucket name>"
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: "ELB"
```

For a fairly exhaustive lists of annotations you can use with AWS's Elastic Load Balancers, see the [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/) page.

## Ingress Annotations

The AWS Load Balancer controller has a wide array of annotations that can be used to configure the ingress, and they are documented on the [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/guide/ingress/annotations.md#actions) GitHub page. Internally, for testing purposes, this example has been used:

```
ingress:
  enable: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
```

This example sets the ingress's class to `alb`, which tells the controller to use an ALB. It tells it to listen on port 80, and it sets the "scheme" to internet-facing, which provisions an ALB with a routable internet address.


## Known EKS Problems

### Persistent Storage Issues

With the logstream-master chart, the default persistent storage (and the CSI driver) use EBS for persistent volumes. EBS volumes are availability-zone–specific. If the EKS cluster is using a single node group that spans availability zones, and a node dies, there's no guarantee that there will be another node on which to schedule it in that availability zone. When that happens, the master pod will sit in an error state until there is a node in that availability zone that can access the EBS volume. 

#### Avoidance

The solution to this is to use availability-zone–aware node groups with autoscaling. Our internal clusters are set up with nodegroups that have a minimum of 1 node and a maximum of 4 nodes, and each nodegroup is in a specific AZ. The `eksctl` docs pages detail the way to deal with this problem – see [https://eksctl.io/usage/autoscaling/#zone-aware-auto-scaling](https://eksctl.io/usage/autoscaling/#zone-aware-auto-scaling). 

### 