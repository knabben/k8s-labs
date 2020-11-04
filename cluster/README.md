
## Drain node in preparation for maintenance.

### kubectl drain

The given node will be marked unschedulable to prevent new pods from arriving.
'drain' evicts the pods if the APIServer supports
[eviction](http://kubernetes.io/docs/admin/disruptions/). Otherwise, it will use normal
DELETE to delete the pods.

The 'drain' evicts or deletes all pods except mirror pods (which cannot be deleted through
the API server).  If there are DaemonSet-managed pods, drain will not proceed
without --ignore-daemonsets, and regardless it will not delete any
DaemonSet-managed pods, because those pods would be immediately replaced by the
DaemonSet controller, which ignores unschedulable markings.  If there are any
pods that are neither mirror pods nor managed by ReplicationController,
ReplicaSet, DaemonSet, StatefulSet or Job, then drain will not delete any pods unless you
use --force.  --force will also allow deletion to proceed if the managing resource of one
or more pods is missing.

'drain' waits for graceful termination. You should not operate on the machine until
the command completes.

When you are ready to put the node back into service, use kubectl uncordon, which
will make the node schedulable again.

![Workflow](http://kubernetes.io/images/docs/kubectl_drain.svg)

### kubectl cordon

Mark node as unschedulable

### kubectl uncordon

Mark node as schedulable

## Kubeadm Upgrade

### kubeadm upgrade plan
### kubeadm upgrade apply

## Etcd Upgrade

### backup
### restore

