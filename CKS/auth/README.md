## Controlling Access to the Kubernetes API

Human users and Kubernetes services accounts can be authorized for API access.
When a request reaches the API, it goes through several stages.

Kubernetes sometimes checks authorization for additional permissions using specialized verbs. For example:

* PodSecurityPolicy - use verb on podsecuritypolicies resources in the policy API group.
* RBAC - bind and escalate verbs on roles and clusterroles resources in the rbac.authorization.k8s.io API group.
* Authentication - impersonate verb on users, groups, and serviceaccounts in the core API group,
  and the userextras in the authentication.k8s.io API group.


# Transport Security - TLS

The API servers on port 443. The certificate is often the root certificate for the API
server's certificate, which when specified is used in place of the system default root
certificate.

Once TLS establishes, the HTTP request moves to the Authentication, this modules includes,
some authentication strategies:

https://kubernetes.io/docs/reference/access-authn-authz/authentication/

## X509 client certs
## Password
## Plain tokens
## Bootstrap tokens
## JWT tokens (service account)

Multiple authentication modules can be specified.

# Authorization

https://blog.styra.com/blog/why-rbac-is-not-enough-for-kubernetes-api-security

After the request is authenticated as coming from a specific user, the rerquest must be authorized.
ABAC / RBAC

# RBAC

The RBAC API declares four kinds of Kubernetes object: Role, ClusterRole, RoleBinding and ClusterRoleBinding.
You can describe objects, or amend them, using tools such as kubectl, just like any other Kubernetes object.

https://kubernetes.io/docs/reference/access-authn-authz/rbac/

### Role and Cluster Role

A Role always sets permissions within a particular namespace; when you create a Role,
you have to specify the namespace it belongs in.


```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: role-pod
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
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

To bind the role or the cluster role you need a binding object for the example

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pod-binding
  namespace: default
subjects:
- kind: User
  name: user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: role-pod
  apiGroup: rbac.authorization.k8s.io
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
