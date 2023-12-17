library(rjson)
library(dplyr)
library(ggplot2)
library(scales)

setwd("/home/vscardel/q_tsch_simulator/master/bin")

# Variáveis para armazenar os resultados
resultados_media <- data.frame()
resultados_join_time <- data.frame()
resultados_lifetime <- data.frame()
resultados_delivery_ratio <- data.frame()

all_results <- c()

NUM_DAYS_YEAR = 365
NUM_MS_IN_TIMESLOT = 10

# Solicitar a pasta do experimento
folder_name <- readline("Digite a pasta do experimento que deseja plotar: ")

file_path <- sprintf("%s/Results/", folder_name)

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
    mean_latencies_list <- c()
    mean_join_time_list <- c()
    mean_lifetime_list <- c()
    mean_upstream_delivery_list <- c()
    
    # Iterar sobre os experimentos
    for (experiment in names(json_data)) {
      
      if ("global-stats" %in% names(json_data[[experiment]])) {
        
        # Acessar os dados relevantes
        global_stats_data <- json_data[[experiment]]$`global-stats`

        latency_info <- global_stats_data$`e2e-upstream-latency`
        mean_latencies <- latency_info[[1]]$mean 

        join_time_info <- global_stats_data$`joining-time`
        #converte em segundos
        mean_join_time <- (join_time_info[[1]]$mean*NUM_MS_IN_TIMESLOT)/60000

        lifetime_info <- global_stats_data$`network_lifetime`
        min_lifetime <- lifetime_info[[1]]$min

        upstream_delivery_info <- global_stats_data$`e2e-upstream-delivery`
        value_upstream_delivery <- upstream_delivery_info[[1]]$value 

        # Armazenar a média
        mean_latencies_list <- c(mean_latencies_list, mean_latencies)
        mean_join_time_list <- c(mean_join_time_list, mean_join_time)
        #converte o lifetime de anos em dias antes de armazenar o resultado
        mean_lifetime_list <- c(mean_lifetime_list,min_lifetime*NUM_DAYS_YEAR)
        mean_upstream_delivery_list <- c(mean_upstream_delivery_list,value_upstream_delivery)
      }
    }
    
    # Calcular a média e o intervalo de confiança da média
    media_latencias <- mean(mean_latencies_list)
    media_join_time <- mean(mean_join_time_list)
    media_lifetime <- mean(mean_lifetime_list)
    media_delivery_ratio <- mean(mean_upstream_delivery_list)
    
    # Adicionar resultados aos dataframes
    nos <- switch(ordem_extracao, 10, 50, 100, 150, 200)

    resultados_media <- bind_rows(resultados_media, data.frame(Nos = nos, Media = media_latencias))
    resultados_join_time <- bind_rows(resultados_join_time, data.frame(Nos = nos, Media = media_join_time))
    resultados_lifetime <- bind_rows(resultados_lifetime, data.frame(Nos = nos, Media = media_lifetime))
    resultados_delivery_ratio <- bind_rows(resultados_delivery_ratio, data.frame(Nos = nos, Media = media_delivery_ratio))

    all_results <- list(resultados_media,resultados_join_time,resultados_lifetime,resultados_delivery_ratio)
  }
}

# Criar uma pasta para os gráficos se não existir
path_to_save <- sprintf("%s/Graphs/", folder_name)
dir.create(path_to_save, showWarnings = FALSE)

graph_file_names = c("latency.jpg","join_time.jpg","lifetime.jpg","delivery_ratio.jpg")
graph_count <- 1

for (result in all_results) {

  current_y_label <- switch(
    graph_count,
    "Média das Latências",
    "Média dos Join Times Em Segundos",
    "Tempo de Vida Médio em Dias",
    "Taxa Média de Entrega dos Pacotes"
  )

  plot_current_graph <- ggplot(result, aes(x = as.factor(Nos), y = Media)) +
    geom_bar(stat = "identity", position = "dodge", fill = "green", alpha = 0.8, width = 0.3) +
    labs(title = current_y_label, x = "Número de Nós", y = "") +
    theme_minimal() +
    scale_y_continuous(breaks = pretty_breaks(n = 10)) +
    theme(
      plot.background = element_rect(fill = "white")
    )

  # Salvar os gráficos no formato JPEG
    ggsave(file.path(path_to_save, graph_file_names[graph_count]), plot = plot_current_graph, width = 8, height = 6, units = "in", dpi = 300)
    graph_count <- graph_count + 1
}
