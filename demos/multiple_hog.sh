#!/bin/bash
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`

let C=NUM_CPUS-1
for i in `seq 0 $C`;do
  cpufreq-set -g performance -c $i || exit -1
done    
echo -1 > /proc/sys/kernel/sched_rt_runtime_us

eval "./cpuhog &"
pid1=$!

eval "./cpuhog &"
pid2=$!

eval "./cpuhog &"
pid3=$!

eval "./cpuhog &"
pid4=$!

sleep 2

schedtool -E -t 10000000:100000000 ${pid1}
schedtool -E -t 15000000:50000000 ${pid2}
schedtool -E -t 30000000:70000000 ${pid3}
schedtool -E -t 65000000:130000000 ${pid4}

sleep 2

schedtool -E -t 5000000:30000000 -e ./cpuhog &

sleep 2

killall cpuhog

sleep 1

for i in `seq 0 $C`;do
  cpufreq-set -g ondemand -c $i || exit -1
done    
echo 950000 > /proc/sys/kernel/sched_rt_runtime_us
