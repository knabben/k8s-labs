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