## System Hardening

### Minimize host OS footprint (reduce attack surface)

* https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/#preventing-containers-from-loading-unwanted-kernel-modules
* CIS_Debian_Linux_10_Benchmark_v1.0.0.pdf

### Minimize IAM roles

[IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

### Minimize external access to the network

* Ingress Deny ALL Netpol - See Cluster setup.

You can set a quote of 0 services for example, disallowing the operator to setup an external 

```
$ kubectl create -f quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-counts
spec:
  hard:
    services: "0"
    services.loadbalancers: "0"

$ kubectl run nginx --image=nginx
pod/nginx created
$ kubectl expose pod/nginx --port 80
Error from server (Forbidden): services "nginx" is forbidden: exceeded quota: object-counts, requested: services=1, used: services=1, limited: services=0
```

* https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/#restricting-network-access
* Firewall (iptables)
  
### Appropriately use kernel hardening tools such as AppArmor, seccomp

#### AppArmor

Until now the apparmor profile loading is made manually. On each node you should
load the profile

```
#include <tunables/global>

profile k8s-apparmor-example-deny-write flags=(attach_disconnected) {
  #include <abstractions/base>

  file,

  # Deny all file writes.
  deny /** w,
}
```

Lets load the profile on a particular node and test a Docker

```
apparmor_parser -a profile
$ cat /sys/kernel/security/apparmor/profiles
k8s-apparmor-example-deny-write (enforce)
docker-default (enforce)

$ docker run --rm -it --security-opt apparmor=k8s-apparmor-example-deny-write debian:jessie sh
# touch /tmp/a
touch: cannot touch '/tmp/a': Permission denied
```

Load up the Pod with annotations, use a node selector for enforce it: 

```
$ kubectl label node gke-cluster-1-default-pool-f427cef2-hd49 apparmor=true
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: localhost/k8s-apparmor-example-deny-write
spec:
  containers:
  - image: busybox
    name: hello
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
  nodeSelector:
    apparmor: true
```

The Pod should not be able to write on FS again.

### Seccomp

Find the node and create a seccomp profile under `/var/lib/seccomp/profiles`. Follow the instructions in the tutorial
and setup a Pod under the seccomp configured node:

```
apiVersion: v1
kind: Pod
metadata:
  name: audit-pod
  labels:
    app: audit-pod
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: localhost/profiles/audit.json
spec:
  containers:
  - name: test-container
    image: busybox
    args:
    - "sleep"
    - "1d"
    securityContext:
      allowPrivilegeEscalation: false
  nodeSelector:
    pod: seccomp
```

You should see some syscall tracings like:
```
Dec 30 00:57:50 gke-cluster-1-default-pool-f427cef2-hd49 audit[25570]: SECCOMP auid=4294967295 uid=0 gid=0 ses=4294967295 subj==unconfined pid=25570 comm="runc:[2:INIT]" exe="/usr/bin/runc" sig=0 arch=c000003e syscall=35 compat=0 ip=0x558e8a32b13d code=0x7ffc0000
Dec 30 00:57:50 gke-cluster-1-default-pool-f427cef2-hd49 audit[25570]: SECCOMP auid=4294967295 uid=0 gid=0 ses=4294967295 subj==docker-default (enforce) pid=25570 comm="sleep" exe="/bin/sleep" sig=0 arch=c000003e syscall=12 compat=0 ip=0x4dd50c code=0x7ffc0000
Dec 30 00:57:50 gke-cluster-1-default-pool-f427cef2-hd49 audit[25570]: SECCOMP auid=4294967295 uid=0 gid=0 ses=4294967295 subj==docker-default (enforce) pid=25570 comm="sleep" exe="/bin/sleep" sig=0 arch=c000003e syscall=12 compat=0 ip=0x4dd50c code=0x7ffc0000
```

References:

* https://kubernetes.io/docs/tutorials/clusters/seccomp/
* https://kubernetes.io/docs/tutorials/clusters/apparmor/
* https://github.com/kubernetes-sigs/security-profiles-operator

