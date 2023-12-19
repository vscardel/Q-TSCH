library(rjson)
library(dplyr)
library(ggplot2)
library(scales)
library(reshape)

extract_nodes_from_filename <- function(filename) {
  # Use expressão regular para extrair o número de nós
  match <- regexec("exec_numMotes_([0-9]+)\\.dat\\.kpi", filename)
  
  # Verifique se houve uma correspondência bem-sucedida
  if (match[[1]][1] != -1) {
    # Extrai o número de nós da correspondência
    num_nodes <- as.integer(sub("exec_numMotes_([0-9]+)\\.dat\\.kpi", "\\1", filename))
    return(num_nodes)
  } else {
    # Retorna NA se não houver correspondência
    return(NA)
  }
}

compute_final_dataframe <- function(file_path) {
  # Inicializa um dataframe vazio
  final_df <- data.frame()

  # Iterar sobre os arquivos
  for (file_name in list.files(file_path)) {
	
    current_file_path <- file.path(file_path, file_name)

    # Verificar se o arquivo é .kpi
    if (grepl(".kpi", current_file_path)) {
      # Ler os dados do JSON
      json_data <- fromJSON(file = current_file_path)

      # Iterar sobre os experimentos no arquivo
      for (i in seq_along(json_data)) {
        # Acessa os dados do i-ésimo experimento
        experiment_data <- json_data[[i]]

        # Filtra os dados para o número específico de nós
        num_nodes <- length(experiment_data)
        nodes_data <- experiment_data[1:(num_nodes - 1)]

        Remover o campo "latencies" de cada nó
        nodes_data <- lapply(nodes_data, function(node) {
          node$latencies <- NULL
          return(node)
        })

        # Converte os dados para um dataframe
        df <- lapply(nodes_data, function(node) {
          if (is.null(node$avg_current_uA)) {
            node$avg_current_uA <- 0
          }
          return(node)
        }) %>%
          as.data.frame()

        print(df)

        # Adiciona uma coluna "Experiment" com o número do experimento
        df$Experiment <- i

        # Adiciona o dataframe ao dataframe final
        final_df <- rbind(final_df, df)
      }
    }
  }

  # Calcula a média para cada métrica agrupada por nó
  final_df_mean <- final_df %>%
    group_by(Experiment, .id = "Node") %>%
    summarise_all(mean, na.rm = TRUE)

  return(final_df_mean)
}

plot_graphs <- function(results_msf,results_q_learning) {
	# Criar uma pasta para os gráficos se não existir
	path_to_save <- sprintf("%s/Graphs/", "/home/vscardel/ResultSimExperiments")
	dir.create(path_to_save, showWarnings = FALSE)

	graph_file_names = c("latency.jpg","join_time.jpg","lifetime.jpg","delivery_ratio.jpg")

	graph_count <- 1

	for (index in seq_along(results_msf)) {

		current_data_frame_msf = results_msf[[index]]
		current_data_frame_q_learning = results_q_learning[[index]]

		combined_data <- data.frame(
			Nos = rep(current_data_frame_msf$Nos, 2),  # Repetir para ter dois conjuntos de barras
			Media = c(current_data_frame_msf$Media, current_data_frame_q_learning$Media),
			Tipo = rep(c("MSF", "Q-Learning"), each = length(current_data_frame_msf$Nos))
		)

		current_y_label <- switch(
			graph_count,
			"Média das Latências",
			"Média dos Join Times Em Segundos",
			"Tempo de Vida Médio em Dias",
			"Taxa Média de Entrega dos Pacotes"
		)

		plot_current_graph <- ggplot(combined_data, aes(x = as.factor(Nos), y = Media, fill = Tipo)) +
		geom_bar(aes(y = Media, fill = Tipo), stat = "identity", position = "dodge", color = "white", width = 0.7, alpha = 0.4) +
		labs(title = current_y_label, x = "Número de Nós", y = "") +
		theme_minimal() +
		scale_y_continuous(breaks = pretty_breaks(n = 10)) +
		theme(plot.background = element_rect(fill = "white")) +
		scale_fill_manual(values = c(rgb(51/255, 187/255, 1), rgb(0, 204/255, 153/255)))

		ggsave(file.path(path_to_save, graph_file_names[graph_count]), plot = plot_current_graph, width = 8, height = 6, units = "in", dpi = 300)
		graph_count <- graph_count + 1
	}
}

setwd("/home/vscardel/q_tsch_simulator/master/bin")

# Solicitar a pasta do experimento
folder_name_msf <- readline("Digite a pasta do experimento MSF que deseja plotar: ")
folder_name_qlearning <- readline("Digite a pasta do experimento Q learning que deseja plotar: ")

#caminho absoluto para a pasta dos resultados da MSF
file_path_msf <- sprintf("%s/Results/", folder_name_msf)

#caminho absoluto para a pasta dos resultados do Q learning
file_path_q_learning <- sprintf("%s/Results/", folder_name_qlearning)


final_df_msf <- compute_final_dataframe(file_path_msf)

final_df_q_learning <- compute_final_dataframe(file_path_q_learning)