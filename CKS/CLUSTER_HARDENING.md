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