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

[kube-psp-advisor](https://github.com/sysdiglabs/kube-psp-advisor) 
This tool from sysdig can inspect and report PSP based on your current environment.

Other references:
* [Chapter 8](https://github.com/PacktPublishing/Learn-Kubernetes-Security/tree/master/chapter08) - Learn Kubernetes Security

#### OPA - *Open Policy Agent*

* OPA Gatekeeper
* Rego
* OPA Playground

##### Security Contexts

https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#podsecuritycontext-v1-core

#### Manage Kubernetes secrets

Secrets

https://kubernetes.io/docs/concepts/configuration/secret/

### Use container runtime sandboxes in multi-tenant environments (gvisor, kata containers)

* gvisor 
* KataContainers
* RuntimeClasses (sandbox)

https://kubernetes.io/docs/concepts/containers/runtime-class/

### Implement pod to pod encryption by use of mTLS

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

