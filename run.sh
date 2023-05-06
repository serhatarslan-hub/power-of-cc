#!/bin/bash

REPEAT_CNT=10
IPERF_DST="10.0.0.1"
IPERF_IFACE="bond0"
IPERF_SIZE="10G"
MTU_SIZES=("1500" "9000")

# Determine the experiment ID
EXP_ID=( $(date +"%y%m%d-%H%M") )
EXP_DIR="./data/$EXP_ID" 
if [ ! -d "$EXP_DIR" ]; then
    mkdir $EXP_DIR
else
    echo "The data directory for this experiment already exists!"
fi
EXP_FILE=$EXP_DIR"/energy.log"

# Measure energy spent for UDP traffic
for MTU_SIZE in ${MTU_SIZES[@]}; do
    sudo ifconfig $IPERF_IFACE mtu $MTU_SIZE up
    for CNT in $(seq $REPEAT_CNT); do
        NRG_0=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj))
        NRG_1=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj))
        iperf3 -c $IPERF_DST -n $IPERF_SIZE -b 0 -u -i 60
        NRG_0=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj)-NRG_0))
        NRG_1=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj)-NRG_1))
        NRG=$((NRG_0+NRG_1))
        echo "cc=udp mtu=$MTU_SIZE energy_uJ=${NRG}" >> $EXP_FILE
    done
done

# Get available congestion control algorithms on this machine
CCA_AVAIL=( $(sysctl net.ipv4.tcp_available_congestion_control | awk -F"=" '{print (NF>1)? $NF : ""}') )
# Measure energy spent for UDP traffic
for CCA in "${CCA_AVAIL[@]}"; do
    sudo sysctl -w net.ipv4.tcp_congestion_control=$CCA
    for MTU_SIZE in ${MTU_SIZES[@]}; do
        sudo ifconfig $IPERF_IFACE mtu $MTU_SIZE up
        for CNT in $(seq $REPEAT_CNT); do
            NRG_0=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj))
            NRG_1=( $(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj))
            iperf3 -c $IPERF_DST -n $IPERF_SIZE -i 60
            NRG_0=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj)-NRG_0))
            NRG_1=$(($(sudo cat /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj)-NRG_1))
            NRG=$((NRG_0+NRG_1))
            echo "cc=$CCA mtu=$MTU_SIZE energy_uJ=${NRG}" >> $EXP_FILE
        done
    done
done

sudo sysctl -w net.ipv4.tcp_congestion_control=cubic

# while true; do
#     cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj
#     sleep 0.1
# done