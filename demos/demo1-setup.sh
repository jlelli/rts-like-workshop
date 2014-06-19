#!/bin/bash
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`

echo "disabling powersaving"
let C=NUM_CPUS-1
for i in `seq 0 $C`;do
  cpufreq-set -g performance -c $i || exit -1
done    

echo "disabling admission control"
echo -1 > /proc/sys/kernel/sched_rt_runtime_us

echo "create a UP system"
for i in `seq 1 $C`;do
  echo 0 > /sys/devices/system/cpu/cpu${i}/online
done

echo "ready for demo1"
