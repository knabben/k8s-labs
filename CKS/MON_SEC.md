## Monitoring, Logging and Runtime Security

### Perform behavioral analytics of syscall process and file activities at the host and container level to detect malicious activies

// todo(knabben) - add more falco debugging examples
// install on worker - KIND, find rules, define a specific scenario, formatting - more options

* [Falco](https://falco.org/docs/)
* https://www.youtube.com/watch?v=fRoTKqH3rHI - Falco TGIK

### Detect threats within physical infrastructure, apps, networks, data, users and workloads

IDS/NIDS

### Detect all phases of attack regardless where it occurs and how it spreads

Some vectors:

* https://github.com/kubernetes-simulator/simulator
* https://securekubernetes.com/

### Perform deep analytics investigation and identification of bad actors whitin environment

* syscall analysis - https://docs.sysdig.com/?lang=en
* https://kubernetes.io/blog/2015/11/monitoring-kubernetes-with-sysdig/

```
|18:41:08|root@buster:[simulator]> strace -cw ls
attack		      cmd		  CONTRIBUTING.md  go.mod   Jenkinsfile		launch-files  main.go	prelude.mk  security.txt	terraform
bin		      code-of-conduct.md  Dockerfile	   go.sum   kubesim		lib	      Makefile	README.md   setup		test
clairctl-linux-amd64  CODEOWNERS	  docs		   HELP.md  launch-environment	LICENSE       pkg	scripts     simulation-scripts	tools
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 44.14    0.006052        2017         3           write
 14.84    0.002035          81        25           mmap
  5.98    0.000821          91         9           mprotect
  5.88    0.000806          80        10           fstat
  5.73    0.000786          71        11           close
  5.64    0.000774          85         9           openat
  4.11    0.000564          80         7           read
  2.55    0.000350         349         1           execve
  1.58    0.000216         108         2         2 statfs
  1.51    0.000207          68         3           brk
  1.20    0.000165          82         2           getdents64
  1.20    0.000164          82         2         2 access
  1.04    0.000142          71         2           ioctl
  1.04    0.000142          70         2           rt_sigaction
  0.88    0.000121         120         1           munmap
  0.64    0.000088          87         1           rt_sigprocmask
  0.52    0.000072          71         1           set_tid_address
  0.51    0.000070          70         1           prlimit64
  0.51    0.000070          69         1           arch_prctl
  0.50    0.000069          69         1           set_robust_list
------ ----------- ----------- --------- --------- ----------------
100.00    0.013713                    94         4 total
```

### Ensure immutability of containers at runtime

* Volumes read-only
```
securityContext:
  readOnlyRootFilesystem: true
```
### Use Audit logs to monitor access

* https://kubernetes.io/docs/tasks/debug-application-cluster/audit/
* https://github.com/knabben/kube-audit

// todo(knabben) Configure audit logging with more detailing
// level / userGroup / resources 
