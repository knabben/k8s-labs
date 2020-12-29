# CKS

I'm using Kind with the following script to setup the required hosts and CNI:

https://github.com/jayunit100/k8sprototypes/blob/master/kind/kind-local-up.sh

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

NOTE: Add a PSP before enabling the admission plugin

* https://kubernetes.io/docs/concepts/policy/pod-security-policy/
* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#podsecuritypolicy-v1beta1-policy
 
The policy can be enforced to a specific user or SA via RBAC.

*Other references:*

* [kube-psp-advisor](https://github.com/sysdiglabs/kube-psp-advisor) - This tool from sysdig can inspect and report PSP based on your current environment.
* [Chapter 8](https://github.com/PacktPublishing/Learn-Kubernetes-Security/tree/master/chapter08) - Learn Kubernetes Security

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

* https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#podsecuritycontext-v1-core

// todo(knabben) psp example with RBAC on a namespace 

#### Manage Kubernetes secrets

base64 data foo and ETCD encryption

* https://kubernetes.io/docs/concepts/configuration/secret/
* https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
* https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file/
  https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

// todo(knabben) encryption on data example

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

## Supply Chain Security

### Minimize base image footprint

* Multi-stage build - https://docs.docker.com/develop/develop-images/multistage-build/

### Secure your supply chain: whitelist allowed image registries, sign and validate images

OPA whitelisting only allowed repositories
```
Rego rule
deny[msg] {
    input.request.kind.kind == "Pod"
    image := input.request.object.spec.containers[_].image
    not startswith(image, "secureoci.com")
    msg = "Not allowed!"
}

Input 
{
  "kind": "AdmissionReview",
  "request": {
    "kind": {
      "kind": "Pod",
      "version": "v1"
    },
    "object": {
      "metadata": {
        "name": "myapp"
      },
      "spec": {
        "containers": [
          {
            "image": "secureoci.com/nginx",
            "name": "nginx-frontend"
          },
          {
            "image": "mysql",
            "name": "mysql-backend"
          }
        ]
      }
    }
  }
}

Output
{
    "deny": [
        "Registry Not allowed: mysql"
    ],
}
```

* ImagePolicyWebhook with external image check.

### Use static analysis of user workloads (e.g. kubernetes resources, docker files)

* [trivy](https://github.com/aquasecurity/trivy)

* [Anchore](https://github.com/anchore/anchore-engine)

### Scan images for known vulnerabilities

* [clair](https://quay.github.io/clair/)

## Monitoring, Logging and Runtime Security

### Perform behavioral analytics of syscall process and file activities at the host and container level to detect malicious activies

// todo(knabben) - add more falco debugging examples
// install on worker - KIND
// find rules
// define a specific scenario
// formatting - more options

* [Falco](https://falco.org/docs/)
* https://www.youtube.com/watch?v=fRoTKqH3rHI - Falco TGIK

### Detect threats within physical infrastructure, apps, networks, data, users and workloads

IDS/NIDS

### Detect all phases of attack regardless where it occurs and how it spreads

Some vectors:

* https://github.com/kubernetes-simulator/simulator
* https://securekubernetes.com/

### Perform deep analytics investigation and identification of bad actors whitin environment

* syscall analysis - https://docs.sysdig.com/?lang=en
* https://kubernetes.io/blog/2015/11/monitoring-kubernetes-with-sysdig/

```
|18:41:08|root@buster:[simulator]> strace -cw ls
attack		      cmd		  CONTRIBUTING.md  go.mod   Jenkinsfile		launch-files  main.go	prelude.mk  security.txt	terraform
bin		      code-of-conduct.md  Dockerfile	   go.sum   kubesim		lib	      Makefile	README.md   setup		test
clairctl-linux-amd64  CODEOWNERS	  docs		   HELP.md  launch-environment	LICENSE       pkg	scripts     simulation-scripts	tools
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 44.14    0.006052        2017         3           write
 14.84    0.002035          81        25           mmap
  5.98    0.000821          91         9           mprotect
  5.88    0.000806          80        10           fstat
  5.73    0.000786          71        11           close
  5.64    0.000774          85         9           openat
  4.11    0.000564          80         7           read
  2.55    0.000350         349         1           execve
  1.58    0.000216         108         2         2 statfs
  1.51    0.000207          68         3           brk
  1.20    0.000165          82         2           getdents64
  1.20    0.000164          82         2         2 access
  1.04    0.000142          71         2           ioctl
  1.04    0.000142          70         2           rt_sigaction
  0.88    0.000121         120         1           munmap
  0.64    0.000088          87         1           rt_sigprocmask
  0.52    0.000072          71         1           set_tid_address
  0.51    0.000070          70         1           prlimit64
  0.51    0.000070          69         1           arch_prctl
  0.50    0.000069          69         1           set_robust_list
------ ----------- ----------- --------- --------- ----------------
100.00    0.013713                    94         4 total
```

### Ensure immutability of containers at runtime

* Volumes read-only
```
securityContext:
  readOnlyRootFilesystem: true
```
### Use Audit logs to monitor access

* https://kubernetes.io/docs/tasks/debug-application-cluster/audit/
* https://github.com/knabben/kube-audit

// todo(knabben) Configure audit logging with more detailing
// level / userGroup / resources 

## [Cluster Setup](./CLUSTER_SETUP.md)

## Cluster Hardening

### Restrict access to Kubernetes API

* https://kubernetes.io/docs/concepts/security/controlling-access/

### Use RBAC to minimize exposure

* https://github.com/knabben/k8s-labs/tree/main/CKS/auth#rbac

### Exercise caution in using service accounts e.g. disable defaults, minimize permissions on newly created ones

```can-i --list --as```

* https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-the-default-service-account-to-access-the-api-server

### Update Kubernetes frequently

Upgrade with Kubeadm - https://github.com/knabben/k8s-labs/tree/main/cluster#kubeadm-upgrade

## System Hardening

### Minimize host OS footprint (reduce attack surface)

* https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/#preventing-containers-from-loading-unwanted-kernel-modules
* CIS_Debian_Linux_10_Benchmark_v1.0.0.pdf

### Minimize IAM roles

[IAM](https://github.com/kubernetes-sigs/security-profiles-operator) on AWS machines

### Minimize external access to the network

* Firewall (iptables)

* Egress Netpol Deny ALL ACL
// todo(knabben) - do an example here

* https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/#restricting-network-access


### Appropriately use kernel hardening tools such as AppArmor, seccomp

* https://kubernetes.io/docs/tutorials/clusters/seccomp/
* https://kubernetes.io/docs/tutorials/clusters/apparmor/
* https://github.com/kubernetes-sigs/security-profiles-operator

// todo(knabben) - seccomp and apparmor profile examples

## References 

* https://killer.sh/
* [Learn Kubernetes Security](https://www.amazon.com/Learn-Kubernetes-Security-orchestrate-microservices-ebook/dp/B087Q9G51R)
* [Kubernetes Security](https://kubernetes-security.info/)
* [Kubernetes Simulator](https://github.com/kubernetes-simulator/simulator)