#!/bin/bash

curl -o /usr/local/bin/cfssl https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/darwin/cfssl
curl -o /usr/local/bin/cfssljson https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/darwin/cfssljson

gcloud config set compute/region us-west1

echo -n "Create network with subnet"
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24

echo -n "Set firewall for internal"
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

echo -n "Set firewall for internal"
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0

echo -n "Add address and list"
gcloud compute addresses create kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"

for i in 0 1; do
  echo -n "Starting instance {i}"
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 50GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done

for i in 0 1; do
  echo -n "Starting worker {i}"
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done

gcloud compute instances list --filter="tags.items=kubernetes-the-hard-way"
