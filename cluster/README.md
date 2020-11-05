
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

### kubectl cordon & uncordon

Mark node as unschedulable, this should patch the Pod with:
 
```
{"spec":{"unschedulable":true}}
```

Apply taints from Node Lifecycle Controller: 

```
  spec:
    podCIDR: 10.244.0.0/24
    podCIDRs:
    - 10.244.0.0/24
    providerID: kind://docker/kind/kind-control-plane
    taints:
    - effect: NoSchedule
      key: node.kubernetes.io/unschedulable
      timeAdded: "2020-11-05T00:05:10Z"
    unschedulable: true
```

The inverse uncordon process mark node as schedulable again.

## Kubeadm Upgrade

### kubeadm upgrade plan
### kubeadm upgrade apply

## Etcd Upgrade

### backup
### restore

