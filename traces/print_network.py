import networkx as nx
import argparse
import json
import matplotlib.pyplot as plt

def build_arguments(parser):
    parser.add_argument('-p', '--file_path',default=".") 
    parser.add_argument('-d', '--destination_path',default=".") 
    parser.add_argument('-g', '--grid_layout',default='n')

def draw_grid_layout(G,destination_path):
    layout = nx.spring_layout(G)
    center_position = layout[0]
    pos = nx.get_node_attributes(G, 'pos')
    color_map = ['green' if node == 0 else 'blue' for node in G.nodes()]
    nx.draw(G, pos=pos, with_labels=True, font_weight='bold',node_color = color_map)
    plt.savefig(destination_path)

def draw_generic_layout(G,destination_path):
    pos = nx.kamada_kawai_layout(G)
    color_map = ['green' if node == 0 else 'blue' for node in G.nodes()]
    nx.draw(G, pos, with_labels=True,node_color = color_map)
    plt.savefig(destination_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Printa uma rede usando NetworkX')
    build_arguments(parser)
    args = parser.parse_args()
    file_path = args.file_path
    destination_path = args.destination_path
    grid_layout = args.grid_layout
    try:
        with open(file_path,'r') as f:
            data = json.load(f)
            G = nx.json_graph.node_link_graph(data)

            if grid_layout == 'y':
                draw_grid_layout(G,destination_path)
            else:
                draw_generic_layout(G,destination_path)
    except OSError as error:
        print(error)