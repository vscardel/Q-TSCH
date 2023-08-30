import subprocess
import json

if __name__ == '__main__':

    UPPER_LIMIT = 11
    FIXED_VALUE = 0.2
    NUM_PARAM = 3
  
    for i in range(NUM_PARAM):

        for param in range(1,UPPER_LIMIT,2):
            param = param / 10
            if i == 0:
                ALFA = param
                BETA = 0.2
                EPSLON = 0.2
            elif i == 1:
                BETA = param
                ALFA = 0.2
                EPSLON = 0.2
            else:
                EPSLON = param
                ALFA = 0.2
                EPSLON = 0.2

            with open("config.json", "r") as jsonFile:
                config_data = json.load(jsonFile)
                config_data["settings"]['regular']['ALFA'] = ALFA
                config_data["settings"]['regular']['BETA'] = BETA
                config_data["settings"]['regular']['EPSLON'] = EPSLON
        
            with open("config.json", "w") as jsonFile:
                json.dump(config_data, jsonFile)

            print("Rodando Iteracao ALFA = {0}, BETA = {1} E EPSLON = {2}".format(ALFA,BETA,EPSLON))
            rc = subprocess.call("python2 runSim.py", shell=True)
