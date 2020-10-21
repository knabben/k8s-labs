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

### Generating PKI with cfssl vs openssl

Generate and usage, on the fly certificate change between components step by step
https://github.com/cloudflare/cfssl

### Signing

https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/

### Component certificates

Port 6443
How to generate TLS cert and private keys to the API Server and accessing it.

```
--tls-cert-file
--tls-private-key-file
--bind-address

Etcd
APIServer
Kubelet
Controller
```

### Kubectl proxy

Explanation of command usage and direct client certs pass

### Controller Certificate CA

approve | deny

### Controlling Access to the Kubernetes API

Human users and Kubernetes services accounts can be authorized for API access.
When a request reaches the API, it goes through several stages.

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

https://kubernetes.io/docs/reference/access-authn-authz/authorization/

# KubeConfig

? 

# Cluster Role and Cluster Role Binding

?