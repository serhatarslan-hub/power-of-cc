import pandas as pd
import numpy as np
import json
import os.path
import matplotlib.colors as mcolors

def get_next_color(index):
    all_colors = mcolors.TABLEAU_COLORS
    color_names = list(all_colors.keys())
    num_colors = len(color_names)
    color_index = index % num_colors
    color_name = color_names[color_index]
    color_value = all_colors[color_name]
    return color_value

def read_energy_log(exp_filename):
    data = []
    with open(exp_filename,'r') as f:
        for line in f:
            exp = {}
            for item in line.split():
                key, val = item.split('=')
                if key in ['energy_uJ', 'duration']:
                    val = float(val)
                elif key in ['mtu', 'bitrate', 'n_core']:
                    val = int(val)
                if (key=='cc' and val=='none'):
                    val = 'baseline' # Using a better name for our custom module
                exp[key] = val
            if val > 0:
                data.append(exp)

    df = pd.DataFrame(data)
    return df

def read_iperf_log(df, data_folder):
    total_cpu_util_percent = []
    user_cpu_util_percent = []
    system_cpu_util_percent = []
    time_sec = []
    sent_bytes = []
    bps = []
    rtx_pkts = []
    min_rtts = []
    mean_rtts = []
    max_rtts = []
    max_cwnds = []
    for _, row in df.iterrows():

        total_cpu_util = np.nan
        user_cpu_util = np.nan
        system_cpu_util = np.nan
        time = np.nan
        sent = np.nan
        thp = np.nan
        rtx = np.nan
        min_rtt = np.nan
        mean_rtt = np.nan
        max_rtt = np.nan
        max_cwnd = np.nan
        
        if (row['cc'] == 'baseline'):
            row['cc'] = 'none' # Revert to the original module name to get iperf data
        json_filename = data_folder + row['cc'] + '_' + str(row['mtu']) + '_' 
        if ('bitrate' in row.keys()):
            json_filename += str(row['bitrate']) + '_'
        if ('duration' in row.keys()):
            json_filename += str(int(row['duration'])) + '_'
            time = row['duration']
        json_filename += row['cnt']
        # if ('n_core' in row.keys() and row['n_core'] != 0):
        if ('n_core' in row.keys()):
            json_filename += '_' + str(int(row['n_core']))
        json_filename += '.json'

        if (os.path.isfile(json_filename)):
            with open(json_filename, 'r') as f:
                iperf_data = json.load(f)

                total_cpu_util = iperf_data['end']['cpu_utilization_percent']['host_total']
                user_cpu_util = iperf_data['end']['cpu_utilization_percent']['host_user']
                system_cpu_util = iperf_data['end']['cpu_utilization_percent']['host_system']
                if row['cc'] == 'udp':
                    sum_str = 'sum' 
                else: 
                    sum_str = 'sum_sent'
                    rtx = iperf_data['end'][sum_str]['retransmits']
                    min_rtt = iperf_data['end']['streams'][0]['sender']['min_rtt'] * 1e-3
                    mean_rtt = iperf_data['end']['streams'][0]['sender']['mean_rtt'] * 1e-3
                    max_rtt = iperf_data['end']['streams'][0]['sender']['max_rtt'] * 1e-3
                    max_cwnd = iperf_data['end']['streams'][0]['sender']['max_snd_cwnd']
                time = iperf_data['end'][sum_str]['seconds']
                sent = iperf_data['end'][sum_str]['bytes']
                thp = iperf_data['end'][sum_str]['bits_per_second']
        elif (row['cc'] not in ['sleep', 'stress']):
            print("{} doesn't exist!".format(json_filename))

        total_cpu_util_percent.append(total_cpu_util)
        user_cpu_util_percent.append(user_cpu_util)
        system_cpu_util_percent.append(system_cpu_util)
        time_sec.append(time)
        sent_bytes.append(sent)
        bps.append(thp)
        rtx_pkts.append(rtx)
        min_rtts.append(min_rtt)
        mean_rtts.append(mean_rtt)
        max_rtts.append(max_rtt)
        max_cwnds.append(max_cwnd)

    df = df.assign(total_cpu_util_percent = total_cpu_util_percent, 
                   user_cpu_util_percent = user_cpu_util_percent, 
                   system_cpu_util_percent = system_cpu_util_percent, 
                   time_sec = time_sec, sent_bytes = sent_bytes, bps = bps, 
                   rtx_pkts = rtx_pkts, min_rtt = min_rtts, 
                   mean_rtt = mean_rtts, max_rtt = max_rtts, 
                   max_cwnd = max_cwnds)
    return df

if __name__ == '__main__':

    # TODO: Print help menu for the helpers
    pass