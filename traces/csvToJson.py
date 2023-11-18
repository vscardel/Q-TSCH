import pandas as pd

df = pd.read_csv('fixedNetwork.k7', header=None, names=['source', 'target', 'value1', 'value2', 'value3'])

connections_count = df['source'].value_counts().reset_index()

connections_count.columns = ['id', 'num_conn']

connections_count = connections_count.sort_values(by='num_conn', ascending=False)

json_output = connections_count.to_json(orient='records', lines=True)

with open('fixedNetwork.json', 'w') as json_file:
    json_file.write(json_output)