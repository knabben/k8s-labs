# Networking

https://github.com/kubernetes/community/blob/master/contributors/design-proposals/network/networking.md

These are the four distinct network [problems](https://kubernetes.io/docs/concepts/cluster-administration/networking/) inside a cluster:

1. Highly-coupled container-to-container communications: this is solved by Pods and localhost communications.
2. Pod-to-Pod communications: this is the primary focus of this document.
3. Pod-to-Service communications: this is covered by services.
4. External-to-Service communications: this is covered by services.

Dynamic port allocation brings a lot of complications to the system - every application has to take ports
as flags, the API servers have to know how to insert dynamic port numbers into configuration blocks, services
have to know how to find each other.

Every POD gets it's own IP address. This means you do not need to explicitly create links between Pods and you
almost never need to deal with mapping containers ports to host ports.

All Pods can reach all other Pods, across Nodes.

## Kernel namespaces and networking

The IP per Pod approach is implemented by the runtime, but uses [kernel namespaces](https://blog.scottlowe.org/2013/09/04/introducing-linux-network-namespaces/)
with this you can have different and separated instances of the network interfaces and routing tables that operate
independent of each other.

You can bind a physical interface to a virtual ethernet interface, and use the virtual one in your network namespace.

```
ip link add veth0 type veth peer name veth1
ip link set veth1 netns <namespace>
ip netns exec blue ip addr add 10.1.1.1/24 dev veth1
ip netns exec blue ip link set dev veth1 up
```

## CNI and Pods network

net-script.conf

### ipam configuration
### DHCP
### host-local
### Kubelet CNI

## CoreDNS

## Kube-Proxy

Watch services and endpoints. Links endpoints (backends) with Services (frontends).
Consider client affinity if requested.

The Kube-proxy runs on each node (as DaemonSet). This reflects services as defined in the Kubernetes API on
each node and can do simple TCP/UDP and SCTP stream forwarding or round-robin TCP/UDP and SCTP forwarding
across a set  of backends. Options to this service are eBPF on CNI likes Cillium. 

## Services

A very good descriptions on how Pod and Services are binding to Endpoints and how this
proxy can keep the reliability of connections on Node or Pod downtime.

![Services](images/services.png)

from [Kubernetes Networking Intro and Deep-Dive - Bowei Du & Tim Hockin](https://www.youtube.com/watch?v=tq9ng_Nz9j8)

## Ingress

https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

It's necessary to install an ingress controller, otherwise the object has no effect:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: example-ingress
spec:
  rules:
  - host: hello-world.info
    http:
      paths:
      - backend:
          serviceName: web
          servicePort: 8080
        path: /
        pathType: Prefix
```

A default backend capable of servicing requests that don't match any rule, can be set
on `ingress.spec.backend`.

You can set rules that match a host, a path and forward the request to a particular
service.

In this case, setup a Pod and service like:

```
kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web --type=NodePort --port=8080
```

### Nginx ingress controller

https://kubernetes.github.io/ingress-nginx/

Install the controller on Kind. We are going to use the NodePort of the service to test 
and evalutate the ingress.

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.41.2/deploy/static/provider/baremetal/deploy.yaml

$ kubectl -n ingress-nginx get pods
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-p7x8t        0/1     Completed   0          28m
ingress-nginx-admission-patch-lsd87         0/1     Completed   0          28m
ingress-nginx-controller-5dbd9649d4-v7c6f   1/1     Running     0          28m
```

Install the Krew plugin and test the created ingress:

```
$ kubectl ingress-nginx ingresses
INGRESS NAME      HOST+PATH           ADDRESSES    TLS   SERVICE   SERVICE PORT   ENDPOINTS
example-ingress   hello-world.info/   172.18.0.2   NO    web       8080           1
```

Create a /etc/hosts with the hostname set in the rules:

```
172.18.0.2 hello-world.info
```

Check the NodePort (this could be behind a cloud LB for example): 

```
$ kubectl get -n ingress-nginx svc
NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.98.143.84     <none>        80:31681/TCP,443:30372/TCP   37m
ingress-nginx-controller-admission   ClusterIP   10.108.111.200   <none>        443/TCP                      37m
```

While hitting the host, check the logs in the Nginx: 

```
$ curl http://hello-world.info:31681
Hello, world!
Version: 1.0.0
Hostname: web-79d88c97d6-l58df

$ kubectl ingress-nginx -n ingress-nginx logs -f
...
10.244.0.1 - - [27/Nov/2020:23:37:23 +0000] "GET / HTTP/1.1" 200 60 "-" "curl/7.64.0" 86 0.001 [default-web-8080]
```