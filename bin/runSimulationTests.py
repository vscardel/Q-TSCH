import argparse
import json
import os
import time
import subprocess
import re
import shutil


def list_of_ints(arg):
    return list(map(int, arg.split(',')))

def define_parameters(parser):
    parser.add_argument('-nr', '--num_runs') 
    parser.add_argument(
        '-app', '--application',
        choices=['AppPredictableBurst','AppIndustrialMonitoring','AppPeriodic']
    )
    parser.add_argument('-topo', '--topology',choices=['Grid','Fixed'])
    parser.add_argument('-cb', '--combinations',type = list_of_ints)    
    
def build_parameters(args):
    parameters = {}
    parameters['num_runs'] = int(args.num_runs)
    parameters['application'] = args.application
    parameters['topology'] = args.topology
    parameters['combinations'] = args.combinations
    parameters['current_num_node'] = 0
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

def build_folder_name():
    timestamp = time.time()
    return str(timestamp)[:10]

def build_subfolder_name(parameters,num_rum):
    application = parameters['application']
    topology = parameters['topology']
    num_nodes = parameters['num_nodes']
    return f'{application}_{topology}_{num_nodes}_{num_rum}'

def create_output_folder(output_folder):
    folder_path = os.path.join("./",output_folder,'Results')
    os.makedirs(folder_path)
    topologies_folder_path = os.path.join("./",output_folder,"Topologies")
    os.makedirs(topologies_folder_path)
    return folder_path

def save_config(output_folder,parameterized_config_file):
    with open(f"{output_folder}/config.json", "w+") as f:
        json.dump(parameterized_config_file,f,indent=2)

def find_simulator_output_folder():
    sim_data_folder_path = './simData'
    folders = os.listdir(sim_data_folder_path)
    for folder_name in folders:
        regex = '[0-9]+-[0-9]+-[0-9]+'
        result = re.search(regex,folder_name)
        if result:
            folder_path = os.path.join(sim_data_folder_path,folder_name)
            return folder_path
            break

def copy_files_from(src_path,dst_path):
    file_names = os.listdir(src_path)
    for file_name in file_names:
        if '.dat' in file_name:
            shutil.copyfile(
                os.path.join(src_path,file_name),
                os.path.join(dst_path,"Results",file_name)
            )

def erase_simulator_output_folder(folder_path):
    shutil.rmtree(folder_path)

def draw_network(dst_path,parameters,num_node):

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
            "python3", 
            "../traces/print_network.py",
            "--file_path",
            network_path,
            "--destination_path",
            dst_path,
            "--grid_layout",
            topology_argument
        ]
    )
        
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

    output_folder_name = build_folder_name() + 'qlearning'

    create_output_folder(output_folder_name)

    for combination in parameters['combinations']:

        parameters['current_num_node'] = combination
        parameterized_config_file = parameterize_config(config_file,parameters)
        save_config(output_folder_name,parameterized_config_file)

        subprocess.run(["python2", "runSim.py","--config",f'{output_folder_name}/config.json'])

        # gambiarra necessaria pois nao achei como fazer o simulador salvar o resultado na pasta q quero

        simulator_folder_output_path = find_simulator_output_folder()

        copy_files_from(
            simulator_folder_output_path,
            output_folder_name
        )

        erase_simulator_output_folder(simulator_folder_output_path)

    for combination in parameters['combinations']:
        draw_network(
            os.path.join("../bin",output_folder_name,"Topologies",f"topology{combination}.png"),
            parameters,
            combination
        )