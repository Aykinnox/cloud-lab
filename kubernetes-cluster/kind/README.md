# kind cluster

Local Kubernetes cluster (kind) with Cilium CNI, running on a dedicated Colima VM.

## Prerequisites

- [Docker CLI](https://docs.docker.com/engine/install/) (`docker`)
- [Colima](https://github.com/abiquo/colima) (`colima`) — provides the Docker runtime via a dedicated VM
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Helm](https://helm.sh/)

## Usage

```bash
./kind.sh create           # start the Colima VM, create the cluster, install Cilium
./kind.sh destroy          # delete the cluster, keep the Colima VM running
./kind.sh destroy --vm     # delete the cluster and the Colima VM
```

`create` is idempotent: it reuses the Colima VM and cluster if they already exist, and
self-heals by recreating the cluster if the existing nodes are unhealthy (e.g. after an
unclean VM restart).

The Colima VM used by this script runs under its own profile (`kind-lab`), isolated from
any other Docker/Colima instance on the machine.
