## Monitoring, Logging and Runtime Security

### Perform behavioral analytics of syscall process and file activities at the host and container level to detect malicious activies

Create a new rule on Falco on `/etc/falco/falco_rules.local.yaml`
```
- macro: container
  condition: container.id != host

- macro: spawned_process
  condition: evt.type = execve and evt.dir=<

- rule: run_shell_in_container
  desc: a shell was spawned by a non-shell program in a container. Container entrypoints are excluded.
  condition: container and proc.name = bash
  output: "Shell spawned (%user.name,container_id=%container.id)"
  priority: WARNING
```

You should see the following logs:

```
21:46:10.887392293: Notice A shell was spawned in a container with an attached terminal (user=root user_loginuid=-1 <NA> (id=3d9b3f12ef50) shell=bash parent=runc cmdline=bash terminal=34816 container_id=3d9b3f12ef50 image=<NA>)
21:46:11.008102763: Warning Shell spawned (root,container_id=3d9b3f12ef50)
```

* [Falco](https://falco.org/docs/)
* [Falco TGIK](https://www.youtube.com/watch?v=fRoTKqH3rHI)

### Detect threats within physical infrastructure, apps, networks, data, users and workloads

IDS/NIDS

### Detect all phases of attack regardless where it occurs and how it spreads

Some vectors:

* https://github.com/kubernetes-simulator/simulator
* https://securekubernetes.com/

### Perform deep analytics investigation and identification of bad actors whitin environment

Install sysdig standalone and run on the host:

```
curl -s https://download.sysdig.com/DRAIOS-GPG-KEY.public | apt-key add -
curl -s -o /etc/apt/sources.list.d/draios.list http://download.sysdig.com/stable/deb/draios.list
apt-get update && apt-get install sysdig
```

In one terminal run:

```
$ while true; do cat  /etc/passwd; sleep 1; done
```

Find the syscall made by `cat` using `sysdig`:
```
sysdig proc.name=cat and evt.type=openat -p "%evt.info | %proc.name"
...
fd=3(<f>/etc/passwd) dirfd=-100(AT_FDCWD) name=/etc/passwd flags=1(O_RDONLY) mode=0 dev=801  | cat
...
```

It's possible to use strace and summarize the options as well:

```
root@hackbox:/etc/falco# strace -p 839438 -wc
strace: Process 839438 attached
^Cstrace: Process 839438 detached
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 99.93    3.366340      187018        18           select
  0.03    0.001046          19        53           clock_gettime
  0.02    0.000583          16        36           rt_sigprocmask
  0.01    0.000487          54         9           write
  0.01    0.000211          23         9           read
  0.00    0.000065          16         4           getpid
  0.00    0.000020          20         1           ioctl
------ ----------- ----------- --------- --------- ----------------
100.00    3.368753                   130           total
```

References:

* syscall analysis - https://docs.sysdig.com/
* https://kubernetes.io/blog/2015/11/monitoring-kubernetes-with-sysdig/

### Ensure immutability of containers at runtime

* Volumes read-only
```
securityContext:
  readOnlyRootFilesystem: true
```

### Use Audit logs to monitor access

audit audit audit
// todo(knabben) Configure audit logging with more detailing
// level / userGroup / resources


References:

* https://kubernetes.io/docs/tasks/debug-application-cluster/audit/
* https://github.com/knabben/kube-audit

