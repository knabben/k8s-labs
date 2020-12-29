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

```
```

10. [Allow traffic with multi-selector](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/10-allowing-traffic-with-multiple-selectors.md)

11. [Deny Egress traffic](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/11-deny-egress-traffic-from-an-application.md)

12. [Deny Egress from a NS](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/12-deny-all-non-whitelisted-traffic-from-the-namespace.md)


References:

* https://kubernetes.io/docs/concepts/services-networking/network-policies/
* https://www.youtube.com/watch?v=3gGpMmYeEO8
* TGIK - [Netpol](https://www.youtube.com/watch?v=gzzq7TGBsL8)

### Use CIS benchmark to review the security configuration of Kubernetes Components

* [Kube-bench](https://github.com/aquasecurity/kube-bench)

### Properly set up Ingress objects with security control (TLS)

* https://kubernetes.io/docs/concepts/services-networking/ingress/
* TLS secret - https://kubernetes.io/docs/concepts/services-networking/ingress/#tls
* Nginx ingress TLS setup - https://kubernetes.github.io/ingress-nginx/user-guide/tls/

// todo(knabben) - Example of Ingress TLS setup

### Protect node metadata and endpoints

* Netpol Egress deny for metadata server access (GCP/Azure/AWS)

13. [Deny Egress external](https://github.com/ahmetb/kubernetes-network-policy-recipes/blob/master/14-deny-external-egress-traffic.md
14. [Deny CIDR external]

// todo(knabben) - Example of Egress deny

### Minimize use of, and access to, GUI elements

* Dashboard deploy w/o NodePort - RBAC access

### Verify platform binaries before deploying

sha256 - https://github.com/kubernetes/kubernetes/releases