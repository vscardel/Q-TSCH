
import random
import gzip

channels = [16, 17, 23, 18, 26, 15, 25, 22, 19, 11, 12, 13, 24, 14, 20, 21]
num_nodes = 50
with open('fixedNetwork.k7','w') as file:
    for src_id in range(num_nodes):
        num_conn = random.randint(1,20)
        for j in range(0,num_conn):
            dst_id = random.randint(0,49)
            channel = random.choice(channels)
            rssi = round(random.uniform(-100.0,-50.0),2)
            pdr = round(random.random(),2)
            line = str(src_id) + "," + str(dst_id) + "," + str(channel) + "," + str(rssi) + "," + str(pdr) + "\n"
            file.write(line)

with open('fixedNetwork.k7', 'rb') as f_in, gzip.open('fixedNetwork.k7.gz', 'wb') as f_out:
    f_out.writelines(f_in)