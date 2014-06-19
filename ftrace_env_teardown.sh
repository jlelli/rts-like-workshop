#/bin/bash
set -e

if [ "$(id -u)" != "0" ]; then
  echo "you must be root to execute this script."
  exit 1
fi

NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`

C=$((NUM_CPUS-1))
for i in `seq 0 $C`;do
	cpufreq-set -g powersave -c $i || exit -1
done    

if mountpoint -q '/debug'; then
  echo 0 > /debug/tracing/tracing_on
  umount /debug
fi
