#!/bin/bash -x

echo -n "Create workers"

for instance in worker-0 worker-1; do
  gcloud compute ssh ${instance} -- "sudo apt-get update && sudo apt-get -y install socat conntrack ipset && sudo swapoff -a"
  gcloud compute ssh ${instance} -- wget -q --show-progress --https-only --timestamping \
    https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.18.0/crictl-v1.18.0-linux-amd64.tar.gz \
    https://github.com/opencontainers/runc/releases/download/v1.0.0-rc91/runc.amd64 \
    https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz \
    https://github.com/containerd/containerd/releases/download/v1.3.6/containerd-1.3.6-linux-amd64.tar.gz \
    https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-proxy \
    https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubelet

  gcloud compute ssh ${instance} -- sudo mkdir -p /etc/containerd/ /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes
  gcloud compute ssh ${instance} -- "mkdir containerd && tar -xvf crictl-v1.18.0-linux-amd64.tar.gz && tar -xvf containerd-1.3.6-linux-amd64.tar.gz -C containerd && sudo tar -xvf cni-plugins-linux-amd64-v0.8.6.tgz -C /opt/cni/bin/"
  gcloud compute ssh ${instance} -- "sudo mv runc.amd64 runc && chmod +x crictl kubectl kube-proxy kubelet runc && sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/ && sudo mv containerd/bin/* /bin/"

  POD_CIDR=$(gcloud compute ssh ${instance} -- "curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr") 
  gcloud compute ssh ${instance} -- cat <<EOF | gcloud compute ssh ${instance} -- sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

  gcloud compute ssh ${instance} -- cat <<EOF | gcloud compute ssh ${instance} -- sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF


 gcloud compute ssh ${instance} -- cat <<EOF | gcloud compute ssh ${instance} -- sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

  gcloud compute ssh ${instance} -- cat <<EOF |  gcloud compute ssh ${instance} -- sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

  gcloud compute ssh ${instance} -- "sudo mv ${instance}-key.pem ${instance}.pem /var/lib/kubelet/ && sudo mv ${instance}.kubeconfig /var/lib/kubelet/kubeconfig && sudo mv ca.pem /var/lib/kubernetes/"

  gcloud compute ssh ${instance} -- cat <<EOF | gcloud compute ssh ${instance} -- sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${instance}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${instance}-key.pem"
EOF


  gcloud compute ssh ${instance} -- cat <<EOF | gcloud compute ssh ${instance} -- sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  gcloud compute ssh ${instance} -- "sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig"
  gcloud compute ssh ${instance} -- cat <<EOF | gcloud compute ssh ${instance} -- sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF

 gcloud compute ssh ${instance} -- cat <<EOF | gcloud compute ssh ${instance} -- sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

 gcloud compute ssh ${instance} -- "sudo systemctl daemon-reload && sudo systemctl enable containerd kubelet kube-proxy && sudo systemctl start containerd kubelet kube-proxy"
done

gcloud compute ssh controller-0 -- "kubectl get nodes --kubeconfig admin.kubeconfig"
echo -n "Setup route between hosts"
for i in 0 1; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
