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

NOTE: Add a PSP before enabling the adminission plugin

* https://kubernetes.io/docs/concepts/policy/pod-security-policy/
* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#podsecuritypolicy-v1beta1-policy
 
The policy can be enforced to a specific user or SA via RBAC.

*Other references:*

* [kube-psp-advisor](https://github.com/sysdiglabs/kube-psp-advisor) - This tool from sysdig can inspect and report PSP based on your current environment.
* [Chapter 8](https://github.com/PacktPublishing/Learn-Kubernetes-Security/tree/master/chapter08) - Learn Kubernetes Security

#### OPA - *Open Policy Agent*

* OPA Gatekeeper
* OPA Playground
* Rego

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

#### Manage Kubernetes secrets

base64 data foo and ETCD encryption

* https://kubernetes.io/docs/concepts/configuration/secret/
* https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
* https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file/
  https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

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

### Secure your supply chain: whitelist allowed image registries, sign and validate images
### Use static analysis of user workloads (e.g. kubernetes resources, docker files)
### Scan images for known vulnerabilities

## Monitoring, Logging and Runtime Security

### Perform behavioral analytics of syscall process and file activities at the host and container level to detect malicious activies
### Detect threats within physical infrastructure, apps, networks, data, users and workloads
### Detect all phases of attach regardless where it occours and how it spreads
### Perform deep analytics investigation and identification of bad actors whitin environment
### Ensure immutability of containers at runtime

## Cluster Setup

### Use Network Security policies to restrict cluster level access
### Use CIS benchmark to review the security configuation of Kubernetes Components
### Properly set up Ingress objects with security control (TLS)
### Protect node metadata and endpoints
### Minimze use of, and access to, GUI elements
### Verify platform binaries before deploying

## Cluster Hardening

### Restrict access to Kubernetes API
### Use RBAC to minimize exposure
### Exercise caution in using service accounts e.g. disable defaults, minimize permissions on newly created ones
### Update Kubernetes frequently

## System Hardening

### Minimize host OS footprint (reduce attack surface)
### Minimize IAM roles
### Minimize external access to the network
### Appropriately use kernel hardening tools such as AppArmor, seccomp

