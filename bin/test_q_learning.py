import subprocess
import json

if __name__ == '__main__':

    UPPER_LIMIT = 11

    for ALFA in range(1,UPPER_LIMIT,2):
        ALFA = float(ALFA) /10
        for BETA in range(1,UPPER_LIMIT,2):
            BETA = float(BETA) /10
            for EPSLON in range(1,UPPER_LIMIT,2):
                EPSLON = float(EPSLON) / 10

                with open("config.json", "r") as jsonFile:
                    config_data = json.load(jsonFile)
                    config_data["settings"]['regular']['ALFA'] = ALFA
                    config_data["settings"]['regular']['BETA'] = BETA
                    config_data["settings"]['regular']['EPSLON'] = EPSLON
                
                with open("config.json", "w") as jsonFile:
                    json.dump(config_data, jsonFile)

                print("Rodando Iteracao ALFA = {0}, BETA = {1} E EPSLON = {2}".format(ALFA,BETA,EPSLON))
                rc = subprocess.call("python2 runSim.py", shell=True)
