# CKS

## Minimize Microservice Vulnerabilities

### Setup appropriate OS level security domains e.g. using PSP, OPA, security context

#### PodSecurityContext

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#podsecuritycontext-v1-core

#### OPA - *Open Policy Agent*

* OPA Gatekeeper
* Rego
* OPA Playground

##### Security Contexts

https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

#### Manage Kubernetes secrets

Secrets

https://kubernetes.io/docs/concepts/configuration/secret/

### Use container runtime sandboxes in multi-tenant environments (gvisor, kata containers)

* gvisor 
* KataContainers
* RuntimeClasses (sandbox)

https://kubernetes.io/docs/concepts/containers/runtime-class/

### Implement pod to pod encryption by use of mTLS

Istio mTLS example
https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/

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

