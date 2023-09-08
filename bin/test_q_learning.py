import subprocess
import json

if __name__ == '__main__':

    UPPER_LIMIT = 11
    FIXED_VALUE = 0.2
  
    for ALFA in range(1,UPPER_LIMIT,2):

        ALFA = float(ALFA)/10

        for BETA in range(1,UPPER_LIMIT,2):

            BETA = float(BETA)/10

            with open("config.json", "r") as jsonFile:
                config_data = json.load(jsonFile)
                config_data["settings"]['regular']['ALFA'] = ALFA
                config_data["settings"]['regular']['BETA'] = BETA
        
            with open("config.json", "w") as jsonFile:
                json.dump(config_data, jsonFile)

            print("Rodando Iteracao ALFA = {0}, BETA = {1}".format(ALFA,BETA))
            rc = subprocess.call("python2 runSim.py", shell=True)
