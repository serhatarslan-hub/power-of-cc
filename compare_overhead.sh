#!/bin/bash

REPEAT_CNT=20
IPERF_DST="10.0.0.1"
IPERF_IFACE="bond0"
MTU_SIZE=1500

# Determine the experiment ID
EXP_ID=( $(date +"%y%m%d-%H%M") )
EXP_DIR="./data/$EXP_ID" 
if [ ! -d "$EXP_DIR" ]; then
    mkdir $EXP_DIR
else
    echo "The data directory for this experiment already exists!"
fi
ENERGY_FILE=$EXP_DIR"/energy.log"

sudo sysctl -w net.ipv4.tcp_congestion_control=cubic
sudo ifconfig $IPERF_IFACE mtu $MTU_SIZE up

# Measure the energy consumption when no process is running on the machine
for ((T=10; T<=100; T+=10)); do
    for CNT in $(seq $REPEAT_CNT); do
        NRG_0=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj))
        NRG_1=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj))
        sleep $T
        NRG_0=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj)-NRG_0))
        NRG_1=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj)-NRG_1))
        NRG=$((NRG_0+NRG_1))
        echo "cc=sleep mtu=$MTU_SIZE duration=$T cnt=$CNT energy_uJ=${NRG}" >> $ENERGY_FILE
    done
done

# Compare Cubic's energy consumption for different flow completion times to see
# if it proportionally grows with the flow completion time
for ((T=10; T<=100; T+=10)); do
    for CNT in $(seq $REPEAT_CNT); do
        JSON_FILE=$EXP_DIR"/cubic_${MTU_SIZE}_${T}_${CNT}.json"
        NRG_0=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj))
        NRG_1=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj))
        iperf3 -c $IPERF_DST -t $T -i 60 --json > $JSON_FILE
        NRG_0=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj)-NRG_0))
        NRG_1=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj)-NRG_1))
        NRG=$((NRG_0+NRG_1))
        echo "cc=cubic mtu=$MTU_SIZE duration=$T cnt=$CNT energy_uJ=${NRG}" >> $ENERGY_FILE
    done
done

# while true; do
#     cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj
#     sleep 0.1
# done