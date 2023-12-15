library(rjson)
library(dplyr)
library(ggplot2)

setwd("/home/vscardel/q_tsch_simulator/master/bin")

# Variáveis para armazenar os resultados
resultados <- data.frame()

# Solicitar a pasta do experimento
file_name <- readline("Digite a pasta do experimento que deseja plotar: ")
file_path <- sprintf("%s/Results/", file_name)
ordem_extracao <- 0
# Iterar sobre os arquivos
for (file_name in list.files(file_path)) {
  
  current_file_path <- paste0(file_path, file_name)
  
  # Verificar se o arquivo é .kpi
  if (grepl(".kpi", current_file_path)) {

    ordem_extracao <- ordem_extracao + 1
    
    # Ler os dados do JSON
    json_data <- fromJSON(file = current_file_path)
    
    # Inicializar vetor para armazenar as médias
    mean_latencies <- c()
    
    # Iterar sobre os experimentos
    for (experiment in names(json_data)) {
      
      if ("global-stats" %in% names(json_data[[experiment]])) {
        
        # Acessar os dados relevantes
        global_stats_data <- json_data[[experiment]]$`global-stats`
        latency_info <- global_stats_data$`e2e-upstream-latency`
        mean <- latency_info[[1]]$mean 
        
        # Armazenar a média
        mean_latencies <- c(mean_latencies, mean)
      }
    }
    
    # Calcular a média e o intervalo de confiança da média
    media <- mean(mean_latencies)
    
    # Adicionar resultados ao dataframe
    nos <- switch(ordem_extracao, 10, 50, 100, 150, 200)

    resultados <- bind_rows(resultados, data.frame(Nos = nos, Media = media))
  }
}
# Plotar os resultados
latencies_graph <- ggplot(resultados, aes(x = as.factor(Nos), y = Media)) +
  geom_bar(stat = "identity", position = "dodge", fill = "skyblue") +
  labs(title = "Média das Médias por Número de Nós", x = "Número de Nós", y = "Média") +
  theme_minimal()

path_to_save <- sprintf("%s/Results/", file_name)
path_to_save <- paste0(path_to_save,"Graficos")
ggsave(file.path(path_to_save, "latencias.png"), plot = latencies_graph, width = 8, height = 6, units = "in")
