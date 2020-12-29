## System Hardening

### Minimize host OS footprint (reduce attack surface)

* https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/#preventing-containers-from-loading-unwanted-kernel-modules
* CIS_Debian_Linux_10_Benchmark_v1.0.0.pdf

### Minimize IAM roles

[IAM](https://github.com/kubernetes-sigs/security-profiles-operator) on AWS machines

### Minimize external access to the network

* Firewall (iptables)
* https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/#restricting-network-access
* Egress Netpol Deny ALL ACL
  // todo(knabben) - do an example here
  
### Appropriately use kernel hardening tools such as AppArmor, seccomp

* https://kubernetes.io/docs/tutorials/clusters/seccomp/
* https://kubernetes.io/docs/tutorials/clusters/apparmor/
* https://github.com/kubernetes-sigs/security-profiles-operator

// todo(knabben) - seccomp and apparmor profile examples