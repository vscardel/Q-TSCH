"""
Plot a stat over another stat.

Example:
    python plot.py --inputfolder simData/numMotes_50/ -x chargeConsumed --y aveLatency
"""
from __future__ import print_function

# =========================== imports =========================================

# standard
from builtins import range
import os
import argparse
import json
import glob
from collections import OrderedDict
import numpy as np

# third party
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# ============================ defines ========================================

KPIS = [
    'latency_max_s',
    'latency_avg_s',
    'latencies',
    'lifetime_AA_years',
    'sync_time_s',
    'join_time_s',
    'upstream_num_lost'
]

# ============================ main ===========================================

def main(options):

    # init
    data_msf = OrderedDict()
    data_qlearning = OrderedDict()

    # chose lastest results
    subfolders = list(
        [os.path.join(options.inputfolder, x) for x in os.listdir(options.inputfolder)]
    )
    subfolder = "simData/ComparisonResults150"

    for key in options.kpis:
        # load data
        file_path_msf = "simData/MSF150/exec_numMotes_150.dat.kpi"
        file_path_qlearning = 'simData/Q-learning150/exec_numMotes_150.dat.kpi'
            
        curr_combination = "exec_numMotes_50"

        with open(file_path_msf, 'r') as f:

            # read kpi file
            kpis_msf = json.load(f)

            # init data list
            data_msf[curr_combination] = []

            # fill data list
            for run in kpis_msf.values():
                for mote in run.values():
                    if key in mote:
                        data_msf[curr_combination].append(mote[key])

        with open(file_path_qlearning, 'r') as f:

            # read kpi file
            kpis_qlearning = json.load(f)

            # init data list
            data_qlearning[curr_combination] = []

            # fill data list
            for run in kpis_qlearning.values():
                for mote in run.values():
                    if key in mote:
                        data_qlearning[curr_combination].append(mote[key])

        # plot
        try:
            if key in ['lifetime_AA_years', 'latencies']:
                plot_cdf(data_msf,data_qlearning,key, subfolder)
            else:
                plot_box(data_msf,data_qlearning,key, subfolder)

        except TypeError as e:
            print("Cannot create a plot for {0}: {1}.".format(key, e))
    print("Plots are saved in the {0} folder.".format(subfolder))

# =========================== helpers =========================================

def plot_cdf(data_msf,data_qlearning, key, subfolder):

    for k, values in data_msf.items():

        # convert list of list to list
        if type(values[0]) == list:
            values = sum(values, [])

        values_msf = [None if value == 'N/A' else value for value in values]
        # compute CDF
        sorted_data = np.sort(values_msf)
        
        yvals = np.arange(len(sorted_data)) / float(len(sorted_data) - 1)
        plt.plot(sorted_data, yvals, label='MSF')
    
    for k, values in data_qlearning.items():

        # convert list of list to list
        if type(values[0]) == list:
            values = sum(values, [])

        values_qlearning = [None if value == 'N/A' else value for value in values]
        # compute CDF
        sorted_data = np.sort(values_qlearning)
        
        yvals = np.arange(len(sorted_data)) / float(len(sorted_data) - 1)
        plt.plot(sorted_data, yvals, label='qlearning')
    
    plt.xlabel(key)
    plt.ylabel("CDF")
    plt.legend()
    savefig(subfolder, key + ".cdf")
    plt.clf()

def plot_box(data_msf, data_qlearning, key, subfolder):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 6), sharey=True)  # Compartilha o eixo y

    # Plotando para data_msf
    ax1.boxplot(list(data_msf.values()))
    ax1.set_xticks(list(range(1, len(data_msf) + 1)))
    ax1.set_xticklabels(list(data_msf.keys()))
    ax1.set_ylabel(key)
    ax1.set_title('MSF')  

    # Plotando para data_qlearning
    ax2.boxplot(list(data_qlearning.values()))
    ax2.set_xticks(list(range(1, len(data_qlearning) + 1)))
    ax2.set_xticklabels(list(data_qlearning.keys()))
    ax2.set_ylabel(key)
    ax2.set_title('Q-Learning')  

    # Ajustando layout
    plt.tight_layout()

    # Salvando a figura
    savefig(subfolder, key)
    
    # Limpeza
    plt.clf()


def savefig(output_folder, output_name, output_format="png"):
    # check if output folder exists and create it if not
    if not os.path.isdir(output_folder):
        os.makedirs(output_folder)

    # save the figure
    plt.savefig(
        os.path.join(output_folder, output_name + "." + output_format),
        bbox_inches     = 'tight',
        pad_inches      = 0,
        format          = output_format,
    )

def parse_args():
    # parse options
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--inputfolder',
        help       = 'The simulation result folder.',
        default    = 'simData',
    )
    parser.add_argument(
        '-k','--kpis',
        help       = 'The kpis to plot',
        type       = list,
        default    = KPIS
    )
    parser.add_argument(
        '--xlabel',
        help       = 'The x-axis label',
        type       = str,
        default    = None,
    )
    parser.add_argument(
        '--ylabel',
        help       = 'The y-axis label',
        type       = str,
        default    = None,
    )
    parser.add_argument(
        '--show',
        help       = 'Show the plots.',
        action     = 'store_true',
        default    = None,
    )
    return parser.parse_args()

if __name__ == '__main__':

    options = parse_args()

    main(options)
