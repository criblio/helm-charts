# pod-killer Helm Chart

# Purpose

This chart creates a CronJob that can delete a pod within the same namespace. The pod to delete is specified in annotations in the values file, with the timing defined in the schedule value in the values file

# Example Values File
```
annotations:
  target-pods: lsms-master

schedule: "*/5 * * * *"
```
