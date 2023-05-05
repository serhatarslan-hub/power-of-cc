while true; do
    cat /sys/class/powercap/intel-rapl/intel-rapl\:0/energy_uj /sys/class/powercap/intel-rapl/intel-rapl\:1/energy_uj
    sleep 0.1
done
