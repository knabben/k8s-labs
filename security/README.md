# PKI

Is a set of roles, policies, hardware, software and procedures needed to create, manage,
distribute, use, store and revoke digital certificates and manage public-key encryption.

A PKI is an arrangement that binds *public keys* with respective identities of entities 
(like people and organizations). The binding is established through a process of
registration and issuance of certificates at and by a certificate authority (CA).

The X.509 standard defines the most commonly used format for public key certificates.

It consists of:

A certificate authority (CA), that stores, issues and signs the digital certificates;
A registration authority (RA), which verifies the identify of the entities requesting their digital certificates to be stored at the CA;
A central directory - a secure location in which keys are stored and indexed;
A certificate management system - managing things like the access to stored certificates or the delivery of the certificates to be issued;
A certificate policy - stating the PKI's requirements concerning it's procedures. It's purpose is to allow outsiders to analyze the PKI's trustworthiness.

https://en.wikipedia.org/wiki/Public_key_infrastructure

## Component certificates

todo(knabben): generate certificates

Port 6443 on API server, How to generate TLS cert and private keys to the API Server and access it.

```
--tls-cert-file
--tls-private-key-file
--bind-address

?

Etcd
APIServer
Kubelet
Controller
```

## Signing

The Certificates API enables automation of X.509 credential provisioning by
providing a programmatic interface for clients of the Kubernetes API to request
and obtain X.509 certificates from a Certificate Authority (CA)

A CertificateSigningRequest (CSR) resource is used to requesty that a certificate
be signed by a denoted signer, after which the request maybe approved or denied
before finally being signed.

As a normal user I can generate my Private Key and a Certificate Signing Request

Try with cfssl-newkey 

```
cat > user-csr.json <<EOF
{
  "CN": "user",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "NY",
      "O": "system:user",
      "OU": "K8s",
      "ST": "NYC"
    }
  ]
}
EOF

$ cfssl-newkey user-csr.json | cfssljson -bare admin
$ cat user-csr.json | base64 | tr -d "\n"

The result should go to bellow *spec.request*:
```

Create a new CertificateSigningRequest:

```
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: user
spec:
  groups:
  - system:authenticated
  request: LS0tLS1CRUdJTiBDRVJUS....
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
```

You can approve and view the certificate with:

```
NAME        AGE   SIGNERNAME                                    REQUESTOR                 CONDITION
user        13s   kubernetes.io/kube-apiserver-client           kubernetes-admin          Pending

$ kubectl certificate approve user
certificatesigningrequest.certificates.k8s.io/user approved
```

https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/


## KubeConfig

After the request is approved is possible to use the Private Key to access the Cluster.

todo(knabben): certificate generation and set to access. 

```
```

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