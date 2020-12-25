# Kubernetes Security

## Public Key Infrastructure

Is a set of roles, policies, hardware, software and procedures needed to create, manage,
distribute, use, store and revoke digital certificates and manage public-key encryption.

A PKI is an arrangement that binds *public keys* with respective identities of entities 
(like people and organizations). The binding is established through a process of
registration and issuance of certificates at and by a certificate authority (CA).

The X.509 standard defines the most commonly used format for public key certificates.

It consists of:

- A certificate authority (CA), that stores, issues and signs the digital certificates;
- A registration authority (RA), which verifies the identify of the entities requesting their digital certificates to be stored at the CA;
- A central directory - a secure location in which keys are stored and indexed;
- A certificate management system - managing things like the access to stored certificates or the delivery of the certificates to be issued;
- A certificate policy - stating the PKI's requirements concerning it's procedures. It's purpose is to allow outsiders to analyze the PKI's trustworthiness.

```
KEY_FILE=.
CERT_FILE=
HOST=.
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=${HOST}/O=${HOST}"
```

## Component certificates

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

### References

- https://en.wikipedia.org/wiki/Public_key_infrastructure
- https://blog.cloudflare.com/introducing-cfssl/


