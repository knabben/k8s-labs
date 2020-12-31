## Minimize Microservice Vulnerabilities

### Setup appropriate OS level security domains e.g. using PSP, OPA, security context

#### Pod Security Policies

Pod Security Policies enable fine-grained authorization of pod creation and updates (at cluster-level). Controls the
attributes of pod specification relevant to security.

| Control Aspect                                      | Field Names                                 |
| ----------------------------------------------------| ------------------------------------------- |
| Running of privileged containers                    | [`privileged`](#privileged)                                |
| Usage of host namespaces                            | [`hostPID`, `hostIPC`](#host-namespaces)    |
| Usage of host networking and ports                  | [`hostNetwork`, `hostPorts`](#host-namespaces) |
| Usage of volume types                               | [`volumes`](#volumes-and-file-systems)      |
| Usage of the host filesystem                        | [`allowedHostPaths`](#volumes-and-file-systems) |
| Allow specific FlexVolume drivers                   | [`allowedFlexVolumes`](#flexvolume-drivers) |
| Allocating an FSGroup that owns the pod's volumes   | [`fsGroup`](#volumes-and-file-systems)      |
| Requiring the use of a read only root file system   | [`readOnlyRootFilesystem`](#volumes-and-file-systems) |
| The user and group IDs of the container             | [`runAsUser`, `runAsGroup`, `supplementalGroups`](#users-and-groups) |
| Restricting escalation to root privileges           | [`allowPrivilegeEscalation`, `defaultAllowPrivilegeEscalation`](#privilege-escalation) |
| Linux capabilities                                  | [`defaultAddCapabilities`, `requiredDropCapabilities`, `allowedCapabilities`](#capabilities) |
| The SELinux context of the container                | [`seLinux`](#selinux)                       |
| The Allowed Proc Mount types for the container      | [`allowedProcMountTypes`](#allowedprocmounttypes) |
| The AppArmor profile used by containers             | [annotations](#apparmor)                    |
| The seccomp profile used by containers              | [annotations](#seccomp)                     |
| The sysctl profile used by containers               | [`forbiddenSysctls`,`allowedUnsafeSysctls`](#sysctl)                      |

To enable the PSP we must enable the admission plugin in the [kube-apiserver](psp/kube-apiserver-psp.yaml) manifest.

The policy can be enforced to a specific user or SA via RBAC, generate PSP from your environment with `kube-psp-advisor`:

```
$ kubectl advise-psp inspect
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  creationTimestamp: null
  name: pod-security-policy-all-20201231015616
spec:
  allowedCapabilities:
  - NET_ADMIN
  allowedHostPaths:
  - pathPrefix: /etc/cni/net.d
    readOnly: true
  - pathPrefix: /run/xtables.lock
    readOnly: true
  - pathPrefix: /lib/modules
    readOnly: true
  fsGroup:
    rule: RunAsAny
  hostNetwork: true
  hostPorts:
  - max: 0
    min: 0
  privileged: true
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - hostPath
  - secret
  - configMap
```

Create a namespace and a serviceaccount under it:

```
$ kubectl create -f psp-example.yaml
...
privileged: false
...

$ kubectl create namespace psp
$ kubectl create serviceaccount -n psp psp-account

$ kubectl create -n psp role psp --verb=use --resource=podsecuritypolicy --resource-name=example  # example - PodSecurityPolicy resource
$ kubectl create rolebinding -n psp pspbinding --role=psp --serviceaccount=psp:psp-account
$ kubectl create rolebinding -n psp fake-editor --clusterrole=edit --serviceaccount=psp:psp-account 
```

Create a new Pod with the service account:

```
$ kubectl auth can-i use podsecuritypolicy/example --as=system:serviceaccount:psp:psp-account
yes
...
$ kubectl --as=system:serviceaccount:psp:psp-account -n psp create -f- <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged
spec:
  containers:
    - name: pause
      image: k8s.gcr.io/pause
      securityContext:
        privileged: true
EOF

Error from server (Forbidden): error when creating "STDIN": pods "privileged" is forbidden: PodSecurityPolicy: unable to admit pod: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]
```

The Policy is applied to this new Service account. 

References:

* https://kubernetes.io/docs/concepts/policy/pod-security-policy/
* [kube-psp-advisor](https://github.com/sysdiglabs/kube-psp-advisor) - This tool from sysdig can inspect and report PSP based on your current environment.
* [Chapter 8](https://github.com/PacktPublishing/Learn-Kubernetes-Security/tree/master/chapter08) - Learn Kubernetes Security
* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#podsecuritypolicy-v1beta1-policy

#### OPA - *Open Policy Agent*

OPA is an open source policy engine that allows policy enforcement in Kubernetes.  Uses a custom language called *Rego*.

* [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper)

OPA uses an admission controller that is a piece of code that intercepts requests to the Kubernetes API server
prior to persistence of the object.

* https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/

Practical exercises with Gatekeeper

* https://katacoda.com/austinheiman/scenarios/open-policy-agent-gatekeeper
* https://www.openpolicyagent.org/docs/latest/kubernetes-primer/
* https://www.openpolicyagent.org/docs/latest/kubernetes-tutorial/

* templates.gatekeeper.sh/v1beta1
* constraints.gatekeeper.sh/v1beta1

*Other References*

* https://www.youtube.com/watch?v=ZJgaGJm9NJE
* https://www.youtube.com/watch?v=RDWndems-sk
* https://play.openpolicyagent.org

#### Pod Security Contexts

A security context defines privilege and access control settings for a Pod or Container.
Security context settings include:

* Discretionary Access Control: Permission to access an object, like a file, is based on user ID (UID) and group ID (GID).
* Security Enhanced Linux (SELinux): Objects are assigned security labels.
* Running as privileged or unprivileged.
* Linux Capabilities: Give a process some privileges, but not all the privileges of the root user.
* AppArmor: Use program profiles to restrict the capabilities of individual programs.
* Seccomp: Filter a process's system calls.
* AllowPrivilegeEscalation: Controls whether a process can gain more privileges than its parent process. This bool directly controls whether the no_new_privs flag gets set on the container process. AllowPrivilegeEscalation is true always when the container is: 1) run as Privileged OR 2) has CAP_SYS_ADMIN.
* readOnlyRootFilesystem: Mounts the container's root filesystem as read-only.

Multiple containers can have different settings and profiles.

References: 

* https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#podsecuritycontext-v1-core

### Manage Kubernetes secrets

To encrypt the key under the etcd storage, enable it on the API-server:

```
  - --encryption-provider-config=/etc/kubernetes/secrets.yaml

apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: Fug86VEqS5eNMdI+Q8v0qEy7jLmhC+qa9aSkIPro3LU= 
    - identity: {}
```

Create a secret on your cluster and consume from etcd:

```
$ kubectl create secret generic secret1 -n default --from-literal=mykey=data

$ ETCDCTL_API=3 etcdctl get /registry/secrets/default/secret1 | hexdump -C
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 73 65 63 72 65 74  |s/default/secret|
00000020  31 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |1.k8s:enc:aescbc|
00000030  3a 76 31 3a 61 3a a0 41  44 7d 19 48 a1 7a 63 2e  |:v1:a:.AD}.H.zc.|
00000040  77 f9 b2 48 22 5e 74 9e  48 80 b4 c1 33 32 7d fa  |w..H"^t.H...32}.|
00000050  af 1a e1 70 41 b0 98 5e  cf 89 d5 9d 1d a6 76 45  |...pA..^......vE|
00000060  33 ce 10 72 2c 76 59 a2  fa e9 f0 6a bd bf 35 1a  |3..r,vY....j..5.|
00000070  71 40 00 e9 25 27 50 0d  8c 3f b7 01 bb c8 d6 3e  |q@..%'P..?.....>|
00000080  9a d7 f2 bf 70 62 e3 c8  80 fa d0 89 a5 dc c8 bf  |....pb..........|
00000090  59 11 98 b6 69 89 63 0e  da 08 10 85 ce 27 d9 b5  |Y...i.c......'..|
000000a0  54 b9 f9 d5 61 fe 85 17  0f 36 01 f8 f8 c6 7c 89  |T...a....6....|.|
000000b0  50 04 6b 07 ff 38 08 c6  2d 04 14 31 d2 9f 13 94  |P.k..8..-..1....|
000000c0  72 0e 2b c0 71 1b e8 79  d4 57 cd 37 9e af f7 f3  |r.+.q..y.W.7....|
000000d0  ce 42 52 58 c3 46 04 f4  c5 89 e1 eb 96 9f 86 95  |.BRX.F..........|
000000e0  c2 58 66 68 a7 47 f6 f0  75 ee f8 a4 2f 2b 71 49  |.Xfh.G..u.../+qI|
000000f0  a1 af a3 20 e0 90 44 4a  c4 5e 88 a9 31 b1 18 87  |... ..DJ.^..1...|
00000100  93 b2 3c 34 37 59 23 9f  18 80 22 d8 91 bf d4 bf  |..<47Y#...".....|
00000110  09 f4 b0 35 fb 26 57 89  57 1a b1 98 e4 ba 35 59  |...5.&W.W.....5Y|
00000120  2a 13 67 7c 5e 88 5d 37  e9 19 2c 57 17 0e db cf  |*.g|^.]7..,W....|
00000130  e2 fd 7b f7 ff 37 0a                              |..{..7.|
00000137
```

References:

* https://kubernetes.io/docs/concepts/configuration/secret/
* https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
* https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file/
* https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/


### Use container runtime sandboxes in multi-tenant environments (gvisor, kata containers)

RuntimeClasses is how you enforce the Pod usage on a particular class in the runtime, some examples
from the KEP:

```
kind: RuntimeClass
apiVersion: node.k8s.io/v1
metadata:
    name: native  # equivalent to 'legacy' for now
handler: runc
---
kind: RuntimeClass
apiVersion: node.k8s.io/v1
metadata:
    name: gvisor
handler: gvisor
---
kind: RuntimeClass
apiVersion: node.k8s.io/v1
metadata:
    name: kata-containers
handler: kata-containers
---
# provides the default sandbox runtime when users don't care about which they're getting.
kind: RuntimeClass
apiVersion: node.k8s.io/v1
metadata:
  name: sandboxed
handler: gvisor
```

Create a [Pod](rclass/pod.yaml) using it.

* gvisor
* KataContainers
* RuntimeClasses (sandbox)

Other references:

* https://kubernetes.io/docs/concepts/containers/runtime-class/
* https://www.katacoda.com/katacontainers/scenarios/deploy-katacontainers-to-minikube
* https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/585-runtime-class#examples

### Implement pod to pod encryption by use of mTLS

Not achievable by default.

* Istio mTLS example
* https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/