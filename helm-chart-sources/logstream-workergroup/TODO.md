# Planned Work

Support for Values:

* securityContext - the "run as" user for LogStream - defaults to root. Will need to chown /opt/cribl and config_volume if set
 ** Implemented in workergroup chart - uses traditional securityContext config in values, but still has to run as root (since we need root privs to execute chown). If specified, it adds a cribl user with the specified uid and gid, chowns /opt/cribl recursively to that user, and then fires off entrypoint.sh as that user.

* workergroup as daemonset - adding option to set "deployment" to either "deployment" or "daemonset" and have it deploy appropriately.
** Implemented in WorkerGroup chart.

* extraInitContainers - full definitions of initcontainers to run prior to workergroup image running - probably only useful when persistence is involved (small use case for workergroup - mostly persistent queueing). Could also be used with extraVolumes to add utilities to the container (though this could get dicey).
** Implemented in WorkerGroup chart.


* extraSecretMounts - full defs of secrets and their mount points. 
** Implemented

* extraConfigMapMounts - full defs of configmaps and their mount points.
** Implemented

* extraVolumeMounts - volumes to mount and their mount points. This will be modeled after grafana's where it can be a volume claim, a host path, or an emptyDir mount.
** Implemented

* rbac.extraClusterRoleRules - additional rules to insert in the ClusterRole created for the workergroup.
** Implemented - also added an apiGroups attribute on the original rbac options. 

* Make semantics for groups consistent across charts (i.e. make the "config.tag" available as config.group while still maintaining compatible)
** Implemented

