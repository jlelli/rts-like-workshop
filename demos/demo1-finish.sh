#!/bin/bash
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`

let C=NUM_CPUS-1

echo "restore SMP"
for i in `seq 1 $C`;do
  echo 1 > /sys/devices/system/cpu/cpu${i}/online
done

echo "enabling powersaving"
for i in `seq 0 $C`;do
  cpufreq-set -g ondemand -c $i
done    

echo "enabling admission control"
echo 950000 > /proc/sys/kernel/sched_rt_runtime_us

