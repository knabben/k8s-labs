#!/bin/bash

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

echo -n "Copy Data encrypt config key"
for instance in controller-0 controller-1; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
