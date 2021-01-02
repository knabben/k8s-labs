## Supply Chain Security

### Minimize base image footprint

* Multi-stage build - https://docs.docker.com/develop/develop-images/multistage-build/

Named multi-stage build:

```
cat > Dockerfile <<EOF
FROM golang:latest AS builder
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html
COPY app.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]
EOF

$ docker build -t app:latest .
```

### Secure your supply chain: whitelist allowed image registries, sign and validate images

OPA whitelisting only allowed repositories:

```
Rego rule
deny[msg] {
    input.request.kind.kind == "Pod"
    image := input.request.object.spec.containers[_].image
    not startswith(image, "secureoci.com")
    msg = "Not allowed!"
}

Input 
{
  "kind": "AdmissionReview",
  "request": {
    "kind": {
      "kind": "Pod",
      "version": "v1"
    },
    "object": {
      "metadata": {
        "name": "myapp"
      },
      "spec": {
        "containers": [
          {
            "image": "secureoci.com/nginx",
            "name": "nginx-frontend"
          },
          {
            "image": "mysql",
            "name": "mysql-backend"
          }
        ]
      }
    }
  }
}

Output
{
    "deny": [
        "Registry Not allowed: mysql"
    ],
}
```

* ImagePolicyWebhook with external image check.

Lets test the Image bouncer docker, basically it's a mock service to the Webhook admission controller. Generate 
the Webhook cert and key passing to the container:

```
$ openssl req  -nodes -new -x509 -keyout webhook-key.pem -out webhook.pem

$ docker run --rm -v `pwd`/webhook-key.pem:/certs/webhook-key.pem:ro \
    -v `pwd`/webhook.pem:/certs/webhook.pem:ro \
    -p 1323:1323 \
    flavio/kube-image-bouncer \
    -k /certs/webhook-key.pem \
    -c /certs/webhook.pem

$ curl -XPOST -k https://localhost:1323/image_policy -d'{
  "apiVersion":"imagepolicy.k8s.io/v1alpha1",
  "kind":"ImageReview",
  "spec":{
    "containers":[
      {
        "image":"myrepo/myimage:v1"
      },
      {
        "image":"myrepo/myimage@sha256:beb6bd6a68f114c1dc2ea4b28db81bdf91de202a9014972bec5e4d9171d90ed"
      }
    ],
    "annotations":{
      "mycluster.image-policy.k8s.io/ticket-1234": "break-glass"
    },
    "namespace":"mynamespace"
  }
}'
{"metadata":{"creationTimestamp":null},"spec":{},"status":{"allowed":true}}
```

The ImagePolicyWebhook uses a configuration file to set options for the behavior of the backend. Setup the service
on Kubernetes

```
$ kubectl create secret tls tls-image-bouncer-webhook \
  --key webhook-key.pem \
  --cert webhook.pem
  
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: image-bouncer-webhook
  name: image-bouncer-webhook
spec:
  ports:
    - name: https
      port: 443
      targetPort: 1323
      protocol: "TCP"
  selector:
    app: image-bouncer-webhook
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-bouncer-webhook
spec:
  selector:
    matchLabels:
      app: image-bouncer-webhook
  template:
    metadata:
      labels:
        app: image-bouncer-webhook
    spec:
      containers:
        - name: image-bouncer-webhook
          image: "flavio/kube-image-bouncer:1.9"
          args:
            - "--cert=/etc/admission-controller/tls/tls.crt"
            - "--key=/etc/admission-controller/tls/tls.key"
            - "--debug"
          volumeMounts:
            - name: tls
              mountPath: /etc/admission-controller/tls
      volumes:
        - name: tls
          secret:
            secretName: tls-image-bouncer-webhook
EOF
```

Create the imagePolicy file `configuration.yaml` and change the `--admission-control-config-file=/etc/kubernetes/config/configuration.yaml`,
Don't forget to enable the Admission plugin into the API-server.

```
# configuration.yaml:
imagePolicy:
  kubeConfigFile: /etc/kubernetes/config/image_config.yaml
  # time in s to cache approval
  allowTTL: 50
  # time in s to cache denial
  denyTTL: 50
  # time in ms to wait between retries
  retryBackoff: 500
  # determines behavior if the webhook backend fails
  defaultAllow: false

# image_config.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/config/webhook.pem
    server: https://image-bouncer-webhook.default:1323/image_policy
  name: bouncer_webhook
contexts:
- context:
    cluster: bouncer_webhook
    user: api-server
  name: bouncer_validator
current-context: bouncer_validator
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/config/apiserver-client.pem
    client-key:  /etc/kubernetes/config/apiserver-client-key.pem`  
```

References:

* https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook
* https://www.openpolicyagent.org/docs/latest/kubernetes-primer/#writing-policies

### Use static analysis of user workloads (e.g. kubernetes resources, docker files)

* [trivy](https://github.com/aquasecurity/trivy)
* [Anchore](https://github.com/anchore/anchore-engine)

### Scan images for known vulnerabilities

* [clair](https://quay.github.io/clair/)
