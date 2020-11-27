## InitContainers

```
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
  # These containers are run during pod initialization
  initContainers:
  - name: install
    image: busybox
    command:
    - wget
    - "-O"
    - "/work-dir/index.html"
    - http://info.cern.ch
    volumeMounts:
    - name: workdir
      mountPath: "/work-dir"
  dnsPolicy: Default
  volumes:
  - name: workdir
    emptyDir: {}

```

The initContainers is created before starting the normal container. 
From the `kuberuntime_manager.SyncPod`:

```
// SyncPod syncs the running pod into the desired pod by executing following steps:
//
//  1. Compute sandbox and container changes.
//  2. Kill pod sandbox if necessary.
//  3. Kill any containers that should not be running.
//  4. Create sandbox if necessary.
//  5. Create ephemeral containers.
//  6. Create init containers.
//  7. Create normal containers.


// Step 6: start the init container.
if container := podContainerChanges.NextInitContainerToStart; container != nil {
    // Start the next init container.
    if err := start("init container", containerStartSpec(container)); err != nil {
        return
    }

    // Successfully started the container; clear the entry in the failure
    klog.V(4).Infof("Completed init container %q for pod %q", container.Name, format.Pod(pod))
}
``` 