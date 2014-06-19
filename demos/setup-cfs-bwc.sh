#!/bin/bash
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "Setting up CFS Bandwidth Control"

mkdir -p /cgroup
if ! mountpoint -q '/cgroup'; then
  mount -t cgroup cgroup_root /cgroup
fi

echo "Creating two groups, g1 has 20/50 ms and g2 has 40/70 ms"
mkdir -p /cgroup/g1
mkdir -p /cgroup/g2

echo 0 > /cgroup/g1/cpuset.cpus
echo 0 > /cgroup/g1/cpuset.mems
echo 20000 > /cgroup/g1/cpu.cfs_quota_us
echo 50000 > /cgroup/g1/cpu.cfs_period_us

echo 0 > /cgroup/g2/cpuset.cpus
echo 0 > /cgroup/g2/cpuset.mems
echo 40000 > /cgroup/g2/cpu.cfs_quota_us
echo 70000 > /cgroup/g1/cpu.cfs_period_us

echo "BWC setup is ready"
