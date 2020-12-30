## Cluster Hardening

### Restrict access to Kubernetes API

In the authentication these methods are enabled.

* X509 client certs
* Password
* Plain tokens
* Bootstrap tokens
* JWT tokens (service account)

Anonymous requests use `system:anonymous`.

Human users and Kubernetes services accounts can be authorized for API access.
When a request reaches the API, it goes through several stages.

Kubernetes sometimes checks authorization for additional permissions using specialized verbs. For example:

* PodSecurityPolicy - use verb on podsecuritypolicies resources in the policy API group.
* RBAC - bind and escalate verbs on roles and clusterroles resources in the rbac.authorization.k8s.io API group.
* Authentication - impersonate verb on users, groups, and serviceaccounts in the core API group,
  and the userextras in the authentication.k8s.io API group.

Two API HTTP ports are available, and only the secure MUST be available:

#### localhost port:

* is intended for testing and bootstrap, and for other components of the master node (scheduler, controller-manager) to talk to the API
* no TLS
* default is port 8080, change with --insecure-port flag.
* default IP is localhost, change with --insecure-bind-address flag.
* request bypasses authentication and authorization modules.
* request handled by admission control module(s).
* protected by need to have host access

#### “Secure port”:

* use whenever possible
* uses TLS. Set cert with --tls-cert-file and key with --tls-private-key-file flag.
* default is port 6443, change with --secure-port flag.
* default IP is first non-localhost network interface, change with --bind-address flag.
* request handled by authentication and authorization modules.
* request handled by admission control module(s). 
* authentication and authorization modules run.

* https://kubernetes.io/docs/concepts/security/controlling-access/
* https://kubernetes.io/docs/reference/access-authn-authz/authentication/

### Use RBAC to minimize exposure



# Authorization

https://blog.styra.com/blog/why-rbac-is-not-enough-for-kubernetes-api-security

After the request is authenticated as coming from a specific user, the request must be authorized.
ABAC / RBAC

# RBAC

The RBAC API declares four kinds of Kubernetes object: Role, ClusterRole, RoleBinding and ClusterRoleBinding.
You can describe objects, or amend them, using tools such as kubectl, just like any other Kubernetes object.


### Role and Cluster Role

Create a ServiceAccount
```
$ kubectl create sa sa-secret
```
A Role always sets permissions within a particular namespace; when you create a Role,
you have to specify the namespace it belongs in.

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: role-pod
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - list
 ```

ClusterRole, by contrast, is a non-namespaced resource. The resources have different names
(Role and ClusterRole) because a Kubernetes object always has to be either namespaced
or not namespaced; it can't be both.

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

### Role Binding and Cluster Role Binding

To bind the role or a clusterrole you need a binding object for the example

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pod-binding
  namespace: default
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: secret-list
subjects:
- kind: ServiceAccount
  name: sa-secret
  namespace: default
```

And for a non-namespaced example:

```
# This cluster role binding allows anyone in the "manager" group to read secrets in any namespace.

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

References:

* https://github.com/knabben/k8s-labs/tree/main/CKS/auth#rbac
* https://github.com/liggitt/audit2rbac
* https://kubernetes.io/docs/reference/access-authn-authz/rbac/

### Exercise caution in using service accounts e.g. disable defaults, minimize permissions on newly created ones

Check RBAC permissions with:

```
$ kubectl auth can-i --list --as=system:serviceaccount:default:haha
Resources                                       Non-Resource URLs   Resource Names   Verbs
...
secrets                                         []                  []               [list]
```

It's possible to avoid the automount of the serviceAccount token on your Pod by default.

References: 

* https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-the-default-service-account-to-access-the-api-server

### Update Kubernetes frequently

Upgrade with Kubeadm - https://github.com/knabben/k8s-labs/tree/main/cluster#kubeadm-upgrade