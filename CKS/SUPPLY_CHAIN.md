## Supply Chain Security

### Minimize base image footprint

* Multi-stage build - https://docs.docker.com/develop/develop-images/multistage-build/

### Secure your supply chain: whitelist allowed image registries, sign and validate images

OPA whitelisting only allowed repositories
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

### Use static analysis of user workloads (e.g. kubernetes resources, docker files)

* [trivy](https://github.com/aquasecurity/trivy)

* [Anchore](https://github.com/anchore/anchore-engine)

### Scan images for known vulnerabilities

* [clair](https://quay.github.io/clair/)
