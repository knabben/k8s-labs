gcloud compute ssh controller-0 -- kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.7.0.yaml
gcloud compute ssh controller-0 -- kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
