import argparse
import json
import os
import time
import subprocess
import re
import shutil
import csv

def list_of_ints(arg):
    return list(map(int, arg.split(',')))

def define_parameters(parser):
    parser.add_argument('-nr', '--num_runs') 
    parser.add_argument(
        '-app', '--application',
        choices=['AppPredictableBurst','AppIndustrialMonitoring','AppPeriodic']
    )
    parser.add_argument('-topo', '--topology',choices=['Grid','Fixed'])
   w
    parser.add_argument('-cb', '--combinations',type = list_of_ints)    
    
def build_parameters(args):
    parameters = {}
    parameters['num_runs'] = int(args.num_runs)
    parameters['application'] = args.application
    parameters['topology'] = args.topology
    parameters['combinations'] = args.combinations
    parameters['current_num_node'] = 0
    parameters['output_path'] = args.output_path
    return parameters

def load_config():
    with open('config.json','r') as f:
        config_file = json.loads(f.read())
    return config_file

def parameterize_config(config_file,parameters):
    current_num_node = parameters['current_num_node']
    #escolhe a aplicacao
    config_file['settings']['regular']['app'] = parameters['application']
    config_file['execution']['numRuns'] = parameters['num_runs']
    #escolhe a topologia
    if parameters['topology'] == "Grid":
        config_file['settings']['regular']['conn_class'] = 'Grid'
    #neste caso, precisamos tambem definir o caminho para o trace file
    elif parameters['topology'] == "Fixed":
        config_file['settings']['regular']['conn_class'] = 'Fixed'
        conn_trace_path = f"../traces/k7_networks_random_stats_v1/fixedNetwork{current_num_node}.k7.gz"
        config_file['settings']['regular']['conn_trace'] = conn_trace_path

    config_file['settings']['combination']['exec_numMotes'] = [current_num_node]
    return config_file

def save_config(output_folder,parameterized_config_file):
    os.makedirs(f'./temp{output_folder}')
    with open(f'./temp{output_folder}/config.json', "w+") as f:
        json.dump(parameterized_config_file,f,indent=2)

def draw_network(dst_path,parameters,num_node):

    print('printando a rede')
    topology = parameters['topology']

    network_path = '../traces'
    topology_argument = 'n'

    if topology == 'Grid':
        network_path = os.path.join(
            network_path,
            'grid_networks',
            f'network_grid_{num_node}.json'
        )
        topology_argument = 'y'
    elif topology == 'Fixed':
        network_path = os.path.join(
            network_path,
            'k7_networks',
            f'network_k7_{num_node}.json'
        )


    subprocess.run(
        [
            "python3.9", 
            "../traces/print_network.py",
            "--file_path",
            network_path,
            "--destination_path",
            dst_path,
            "--grid_layout",
            topology_argument
        ]
    )

def compute_mean_node_data(node,experiments_mean_results):
    node_data_list = experiments_mean_results[node]
    mean_dictionary = {}
    for node_data in node_data_list:
        for key,value in node_data.items():
            if value in (None,'N/A'):
                value = 0
            if key not in mean_dictionary:
                mean_dictionary[key] = [value]
            else:
                mean_dictionary[key].append(value)
    for key in mean_dictionary:
        list_data = mean_dictionary[key]
        mean_data = sum(list_data)/len(list_data)
        mean_dictionary[key] = mean_data
    return mean_dictionary

def generate_mean_dictionaty_list(kpi_file_path):
    final_mean_dict = {}
    experiments_run_nodes_list = {}
    with open(kpi_file_path,'r') as f:
        json_file = json.load(f)
        for experiment in json_file:
            for node in json_file[experiment]:
                if node == "global-stats":
                    continue
                current_node_data = json_file[experiment][node]
                current_node_data.pop("latencies",None)
                if node not in experiments_run_nodes_list:
                    experiments_run_nodes_list[node] = [current_node_data]
                else:
                    experiments_run_nodes_list[node].append(current_node_data)
    for node in experiments_run_nodes_list:
        final_mean_dict[int(node)] = compute_mean_node_data(node,experiments_run_nodes_list)
    return final_mean_dict

def save_kpi_in_csv_format(output_folder_name):
    print('Salvado resultados CSV')
    path_to_files = os.path.join('./simData',output_folder_name)
    file_names = os.listdir(path_to_files)
    for file_name in file_names:
        if 'kpi' in file_name:
            kpi_file_path = os.path.join(path_to_files,file_name)
            #tira o .dat e o .csv
            file_name_no_extension = file_name[:-8]
            csv_path = os.path.join(path_to_files,f'{file_name_no_extension}.csv')
            mean_data = generate_mean_dictionaty_list(kpi_file_path)
            with open(csv_path, 'w', newline='') as arquivo_csv:
                csv_writer = csv.DictWriter(arquivo_csv, fieldnames=mean_data[1].keys())
                csv_writer.writeheader()
                # Escreve os dados
                for no, dados in mean_data.items():
                    csv_writer.writerow(dados)

def erase_tempfile(path):
    shutil.rmtree(path)

if __name__ == '__main__':

    #Format of parameters
    # parameters = {
    #     "num_runs":None
    #     "application":None,
    #     "topology":None,
    #     "num_nodes":None
    # }

    parser = argparse.ArgumentParser(
        prog ='Simulation Runner',
        description =
        '''
        Run the simulations using 
        the provided parameters and 
        store its results on the userfolder 
        of choice''',
    )

    define_parameters(parser)
    args = parser.parse_args()
    parameters = build_parameters(args)

    config_file = load_config()

    for combination in parameters['combinations']:

        parameters['current_num_node'] = combination
        parameterized_config_file = parameterize_config(config_file,parameters)
        output_path = parameters['output_path']
        save_config(output_path,parameterized_config_file)

        #3 tentativas
        for i in range(3):
            try:
                print(f'tentativa {i} de rodar a simulacao')
                subprocess.run(["python2", "runSim.py","--config",f'./temp{output_path}/config.json','--output_path',parameters['output_path']])
                break
            except:
                pass
            
        #csv com as medias dos experimentos
        save_kpi_in_csv_format(os.path.join(parameters['output_path'],f'exec_numMotes_{combination}'))
        erase_tempfile(f'./temp{output_path}')

    for combination in parameters['combinations']:
        draw_network(
            os.path.join("../bin","simData",output_path,f"topology{combination}.png"),
            parameters,
            combination
        )