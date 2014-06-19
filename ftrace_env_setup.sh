#/bin/bash
set -e

if [ "$(id -u)" != "0" ]; then
  echo "you must be root to execute this script."
  exit 1
fi

NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`

C=$((NUM_CPUS-1))
for i in `seq 0 $C`;do
	cpufreq-set -g performance -c $i || exit -1
done    

mkdir -p /debug
 
if ! mountpoint -q '/debug'; then
  mount -t debugfs none /debug
fi

echo 0 > /debug/tracing/tracing_on
echo 0 > /debug/tracing/options/sleep-time
echo function > /debug/tracing/current_tracer
