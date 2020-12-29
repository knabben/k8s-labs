## Cluster Setup

### Use Network Security policies to restrict cluster level access

To test netpol, follows the setup of different CNIs using Kind - https://thefind.live/posts/netpol/readme/

#### [Netpol Tutorial](https://github.com/ahmetb/kubernetes-network-policy-recipes)

Create the Pod A and Pod B:

```
kubectl apply \
-f https://raw.githubusercontent.com/knabben/k8s-labs/main/CKS/netpol/pod-a.yaml \
-f https://raw.githubusercontent.com/knabben/k8s-labs/main/CKS/netpol/pod-b.yaml
kubectl expose pod/a --port=80
kubectl expose pod/b --port=80
```

1. [Deny ALL](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/01-deny-all-traffic-to-an-application.md)

```
$ kubectl exec b -- /agnhost connect a:80 --timeout=1s  # OK
```

Apply the Deny ALL traffic, the command should timeout.

```
kubectl create -f https://raw.githubusercontent.com/knabben/k8s-labs/main/CKS/netpol/web-deny-all.yaml
...
spec:
  podSelector:
    matchLabels:
      pod: a
  ingress: []
...
networkpolicy.networking.k8s.io/web-deny-all created

$ kubectl exec b -- /agnhost connect a:80 --timeout=1s  # OK
TIMEOUT
command terminated with exit code 1
```

2. [Limit traffic Ingress to a Pod](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/02-limit-traffic-to-an-application.md) (Ingress + PodSelector (label))

```
$ kubectl create -f https://raw.githubusercontent.com/knabben/k8s-labs/main/CKS/netpol/api-allow.yaml
...
spec:
  podSelector:
    matchLabels:
      pod: a
  ingress:
  - from:
      - podSelector:
          matchLabels:
            pod: b
$ kubectl exec b -- /agnhost connect a:80 --timeout=2s  # OK

Apply with empty ingress rule.
 
...
ingress:
- {}
...

$ kubectl exec b -- /agnhost connect a:80 --timeout=2s  # OK
```

3. [Deny ALL in NS](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/03-deny-all-non-whitelisted-traffic-in-the-namespace.md)

```
$ kubectl create -f https://raw.githubusercontent.com/knabben/k8s-labs/main/CKS/netpol/deny-all.yaml
...
spec:
  podSelector: {}
  ingress: []
... 
$ kubectl exec a -- /agnhost connect b:80 --timeout=2s  # OK
TIMEOUT
$ kubectl exec b -- /agnhost connect a:80 --timeout=2s  # OK
TIMEOUT
```

4. [Deny ALL from other NS](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/04-deny-traffic-from-other-namespaces.md)

Create a `team-a` namespace:

```
$ kubectl create ns team-a
$ kubectl apply -n team-a -f pod-a.yaml -f pod-b.yaml
$ kubectl expose -n team-a pod/a --port=80
$ kubectl expose -n team-a pod/b --port=80
$ kubectl create -f deny-from-ns-other-ns.yaml
...
metadata:
  namespace: team-a
  name: deny-from-other-namespaces
spec:
  podSelector:
    matchLabels:
  ingress:
  - from:
    - podSelector: {}
...

$ kubectl exec b -- /agnhost connect a.team-a:80 --timeout=2s  # OK
TIMEOUT
$ kubectl exec a -- /agnhost connect a.team-a:80 --timeout=2s  # OK
TIMEOUT  
```

5. [Allow from NS](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/05-allow-traffic-from-all-namespaces.md)

```
$ kubectl create ns team-a
$ kubectl apply -n team-a -f pod-a.yaml
$ kubectl expose -n team-a pod/a --port=80

$ kubectl create -f deny-all.yaml -n team-a  # deny all on team-a NS
$ kubectl create -f web-allow-ns.yaml -n team-a  # allow connection from other NS

...
spec:
  podSelector:
    matchLabels:
      pod: a
  ingress:
  - from:
    - namespaceSelector: {}
...
```

Hitting from Pods not in the selector should fail:

```
$ kubectl exec a -- /agnhost connect b.team-a:80 --timeout=2s  # FAIL
TIMEOUT
$ kubectl exec a -- /agnhost connect a.team-a:80 --timeout=2s  # OK
```

6. [Allow traffic from a NS](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/06-allow-traffic-from-a-namespace.md)

```
$ kubectl label namespace/team-a purpose=production
$ kubectl create -f web-allow-prod.yaml
...
spec:
  podSelector:
    matchLabels:
      pod: a
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: production
...
```

Remove the label from the namespace and you will have a timeout.

```
$ kubectl label ns team-a purpose-
$ kubectl exec -n team-a a -- /agnhost connect a.default:80 --timeout=2s
TIMEOUT
```

7. [Allow traffic from some pods](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/07-allow-traffic-from-some-pods-in-another-namespace.md)

Label the correct pods and namespaces from the ingress rule

```
$ kubectl create -f web-allow-all-ns-mon.yaml
$ kubectl label ns team-a team=operations
$ kubectl label pod/a -n team-a type=monitoring
```

a.team-a can access a.default, but b.team-a cannot.

``` 
$ kubectl exec -n team-a a -- /agnhost connect a.default:80 --timeout=2s  # OK
$ kubectl exec -n team-a b -- /agnhost connect a.default:80 --timeout=2s  # FAIL
TIMEOUT
```

8. [Allow external clients](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/08-allow-external-traffic.md)

Allow external clients as well.

```
spec:
  podSelector:
    matchLabels:
      pod: a
  ingress:
  - from: []
```

9. [Allow traffic only to a port](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/09-allow-traffic-only-to-a-port.md)

We should allow only port 81 on `a.default`

```
$ kubectl create -f api-allow-81.yaml
...
spec:
  podSelector:
    matchLabels:
      pod: a
  ingress:
  - from:
    ports:
    - protocol: TCP
      port: 81
...
$ kubectl exec -n team-a a -- /agnhost connect a.default:80 --timeout=2s
TIMEOUT 
$ kubectl exec -n team-a a -- /agnhost connect a.default:81 --timeout=2s
REFUSED
```

10. [Allow traffic with multi-selector](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/10-allowing-traffic-with-multiple-selectors.md)

```
$ kubectl create -f multilabel-svc.yaml
...
spec:
  podSelector:
    matchLabels:
      pod: a
  ingress:
  - from:
    - podSelector:
        matchLabels:
          pod: b
          team: b
...
$ kubectl label pod/b team=b
$ kubectl exec b -- /agnhost connect a.default:80 --timeout=2s

$ kubectl exec -n team-a a -- /agnhost connect a.default:80 --timeout=2s 
TIMEOUT
```

11. [Deny Egress traffic](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/11-deny-egress-traffic-from-an-application.md)

```
$ kubectl create -f b-deny-egress.yaml
spec:
  podSelector:
    matchLabels:
      pod: b
  policyTypes:
  - Egress
  egress: []
$  kubectl exec b -- /agnhost connect a.default:80 --timeout=2s
TIMEOUT 
```

12. [Deny Egress from a NS](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/12-deny-all-non-whitelisted-traffic-from-the-namespace.md)

```
$ kubectl create -f deny-egress-ns.yaml 
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
$ kubectl exec b -- /agnhost connect a.default:80 --timeout=2s
TIMEOUT
```

References:

* TGIK - [Netpol](https://www.youtube.com/watch?v=gzzq7TGBsL8)
* https://www.youtube.com/watch?v=3gGpMmYeEO8
* https://kubernetes.io/docs/concepts/services-networking/network-policies/

### Use CIS benchmark to review the security configuration of Kubernetes Components

Running CIS benchmark 

Following some good practies, you can run `Kube-bench` in a Cluster master:

```
./kube-bench --config-dir `pwd`/cfg --config `pwd`/cfg/config.yaml master
```

The errors/solutions are self explanatories, some examples:

```
1.2.16 Follow the documentation and create Pod Security Policy objects as per your environment.
Then, edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
on the master node and set the --enable-admission-plugins parameter to a
value that includes PodSecurityPolicy:
--enable-admission-plugins=...,PodSecurityPolicy,...
Then restart the API Server.
...
[FAIL] 1.2.16 Ensure that the admission control plugin PodSecurityPolicy is set (Automated)
```

```
On /etc/kubernetes/manifests/kube-apiserver.yaml, enable it:

    - --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
    
The apiserver will restart, be careful, to have at least an initial PSP setup.
```

Rerunning kube-bench again:

```
[PASS] 1.2.16 Ensure that the admission control plugin PodSecurityPolicy is set (Automated)
```

References:

* [Kube-bench](https://github.com/aquasecurity/kube-bench)
* https://www.youtube.com/watch?v=fVqCAUJiIn0 - DIY Pen-Testing for Your Kubernetes Cluster

### Properly set up Ingress objects with security control (TLS)

* https://kubernetes.io/docs/concepts/services-networking/ingress/
* TLS secret - https://kubernetes.io/docs/concepts/services-networking/ingress/#tls
* Nginx ingress TLS setup - https://kubernetes.github.io/ingress-nginx/user-guide/tls/

// todo(knabben) - Example of Ingress TLS setup

### Protect node metadata and endpoints

* Netpol Egress DENY for Metadata server access (GCP)

Running from a inside a Pod we can reach the metadata server.

```
/ # wget -qO- http://metadata.google.internal/  # 169.254.169.254/32
0.1/
computeMetadata/
```

NOTE: Any process that can query the metadata URL, has access to all values in the metadata server.
This includes any custom metadata values that you write to the server. Google recommends that you exercise 
caution when writing sensitive values to the metadata server or when running third-party processes.

Meaning we MUST not allow our applications to read/write metadata information from the cloud provider,
without necessity, for this we will create a Block rule for the external server:

```
$ kubectl create -f deny-metadata.yaml

kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-metadata.yaml
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except: 
        - 169.254.169.254/32

$ kubectl exec -it sandbox -c sandbox 
/ #  wget -qO- http://metadata.google.internal/ -T2
wget: download timed out
/ # wget -qO- https://wwww.google.com
```

What if a Container needs to access the metadata server?

```
$ kubectl create -f allow-metadata.yaml
spec:
  podSelector:
    matchLabels:
      pod: a
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 169.254.169.254/32
```

* https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy
* https://cloud.google.com/compute/docs/storing-retrieving-metadata

### Minimize use of, and access to, GUI elements

* [Install dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

Dashboard must be deploy w/o NodePort - RBAC access

To protect your cluster data, Dashboard deploys with a minimal RBAC configuration by default. 
Currently, Dashboard only supports logging in with a Bearer Token.

At this point the default setup already have the correct cleanup traits. Even if we skip auth in the dashboard
the default SA used is limited to certain resources in the NS.  

```
error
namespaces is forbidden: User "system:serviceaccount:kubernetes-dashboard:kubernetes-dashboard" cannot list resource "namespaces" in API group "" at the cluster scope

$ kubectl auth can-i --list -n kubernetes-dashboard --as=system:serviceaccount:kubernetes-dashboard:kubernetes-dashboard
selfsubjectaccessreviews.authorization.k8s.io   []                  []                                  [create]
selfsubjectrulesreviews.authorization.k8s.io    []                  []                                  [create]
nodes.metrics.k8s.io                            []                  []                                  [get list watch]
pods.metrics.k8s.io                             []                  []                                  [get list watch]
secrets                                         []                  [kubernetes-dashboard-certs]        [get update delete]
secrets                                         []                  [kubernetes-dashboard-csrf]         [get update delete]
secrets                                         []                  [kubernetes-dashboard-key-holder]   [get update delete]
configmaps                                      []                  [kubernetes-dashboard-settings]     [get update]
                                                [/api/*]            []                                  [get]
                                                [/api]              []                                  [get]
                                                [/apis/*]           []                                  [get]
                                                [/apis]             []                                  [get]
                                                [/healthz]          []                                  [get]
                                                [/healthz]          []                                  [get]
                                                [/livez]            []                                  [get]
                                                [/livez]            []                                  [get]
                                                [/openapi/*]        []                                  [get]
                                                [/openapi]          []                                  [get]
                                                [/readyz]           []                                  [get]
                                                [/readyz]           []                                  [get]
                                                [/version/]         []                                  [get]
                                                [/version/]         []                                  [get]
                                                [/version]          []                                  [get]
                                                [/version]          []                                  [get]
services/proxy                                  []                  [dashboard-metrics-scraper]         [get]
services/proxy                                  []                  [heapster]                          [get]
services/proxy                                  []                  [http:dashboard-metrics-scraper]    [get]
services/proxy                                  []                  [http:heapster:]                    [get]
services/proxy                                  []                  [https:heapster:]                   [get]
services                                        []                  [dashboard-metrics-scraper]         [proxy]
services                                        []                  [heapster]                          [proxy]
```

### Verify platform binaries before deploying

SHA512 - https://github.com/kubernetes/kubernetes/releases

```
Fetch the same 
wget https://dl.k8s.io/v1.19.1/kubernetes-server-linux-amd64.tar.gz
tar zxvf kubernetes-server-linux-amd64.tar.gz
```

Lets check the Scheduler binary checksum:

```
sha512sum kubernetes/server/bin/kube-scheduler
2a4bb04344dace2432189d39f300c41d1ea06a0fce049cb422ab7310055de0cea47280486a34f28ac9d98f99b5f0a80e324309899d52c564d20af3f403dec623  kube-scheduler
```