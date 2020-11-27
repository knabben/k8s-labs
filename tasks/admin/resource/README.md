## Create a new namespace

```
kubectl create namespace control-ns
```

### Default memory and limits

Create a LimitRange object with default limits and requests:

```
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
  - default:
      memory: 128Mi
      cpu: 0.5
    defaultRequest:
      memory: 128Mi
      cpu: 0.5
    type: Container
```

Check the default limits for a new pod:

````
kubectl -n control-ns get pod -o jsonpath='{.items[].spec.containers[].resources}'
{"limits":{"cpu":"500m","memory":"128Mi"},"requests":{"cpu":"500m","memory":"128Mi"}}
````

## ResourceQuotas

Referencing objects:

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#resourcequota-v1-core

On the same namespace create a resource quota:

```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-cpu-demo
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
```

Creating a Pod outside the quota will generate issues, as the example:

```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    resources:
      limits:
        memory: "2Gi"
        cpu: "800m"
      requests:
        memory: "2Gi"
        cpu: "400m"
```

Raises this error:

```
 kubectl -n control-ns create -f pod.yaml
Error from server (Forbidden): error when creating "pod.yaml": pods "nginx" is forbidden: 
exceeded quota: mem-cpu-demo, requested: limits.memory=2Gi,requests.memory=2Gi, 
used: limits.memory=128Mi,requests.memory=128Mi, limited: limits.memory=2Gi,requests.memory=1Gi
```