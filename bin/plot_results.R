library(rjson)
library(dplyr)
library(ggplot2)
library(scales)
library(reshape)
library(tidyr)


plot_boxplots <- function(df_msf, df_q_learning, path_to_save, file_name, metric_name) {
  
  # Adiciona uma coluna Experimento aos dataframes
  df_msf$Experimento <- "MSF"
  df_q_learning$Experimento <- "Q-Learning"

  # Juntar os dataframes
  df_plot <- rbind(df_msf, df_q_learning)

  # Criar o gráfico de boxplots
  plot_current_graph <- ggplot(df_plot, aes(x = as.factor(Experimento), y = get(metric_name), fill = Experimento)) +
    geom_boxplot(alpha = 0.8) +
    labs(title = paste("Boxplot para", metric_name, "por Número de Nós"),
         x = "Número de Nós",
         y = metric_name) +
    theme_minimal() +
			scale_y_continuous(breaks = pretty_breaks(n = 10)) +
		theme(plot.background = element_rect(fill = "white")) +
    scale_fill_manual(values = c(rgb(51/255, 187/255, 1), rgb(0, 204/255, 153/255)))

  # Salvar o gráfico
  ggsave(file.path(path_to_save, file_name), plot = plot_current_graph, width = 8, height = 6, units = "in", dpi = 300)
}

plot_bar_graph_averages <- function(dfs_msf,dfs_q_learning,column_name,graph_legend,path_to_save,file_name) {
	
	calculate_average <- function(dataframes, column_name) {
		averages <- sapply(dataframes, function(df) mean(df[[column_name]]))
		return(averages)
	}

	averages_msf <- calculate_average(dfs_msf, column_name)
	averages_q_learning <- calculate_average(dfs_q_learning, column_name)

	df_plot <- data.frame(
		Nos = c(10, 50, 100, 150, 200),
		Media_MSF = averages_msf,
		Media_Q_Learning = averages_q_learning
	)

	df_plot_long <- df_plot %>% pivot_longer(cols = c(Media_MSF, Media_Q_Learning), names_to = "Tipo", values_to = "Media")

	plot_current_graph <- ggplot(df_plot_long, aes(x = as.factor(Nos), y = Media, fill = Tipo)) +
	geom_bar(stat = "identity", position = "dodge", color = "white", width = 0.7, alpha = 0.8) +
	labs(title = paste(graph_legend, "em relação ao Número de Nós"),
		x = "Número de Nós",
		y = paste("Média de", graph_legend)) +
	theme_minimal() +
		scale_y_continuous(breaks = pretty_breaks(n = 10)) +
		theme(plot.background = element_rect(fill = "white")) +
	scale_fill_manual(values = c(rgb(51/255, 187/255, 1), rgb(0, 204/255, 153/255)))

	ggsave(file.path(path_to_save, file_name), plot = plot_current_graph, width = 8, height = 6, units = "in", dpi = 300)
}

setwd("/home/vscardel/q_tsch_simulator/master/bin")

# Solicitar a pasta do experimento
folder_name_msf <- readline("Digite a pasta do experimento MSF que deseja plotar: ")
folder_name_qlearning <- readline("Digite a pasta do experimento Q learning que deseja plotar: ")


#caminho absoluto para a pasta dos resultados da MSF
file_path_msf <- sprintf("%s/Results/", folder_name_msf)

#caminho absoluto para a pasta dos resultados do Q learning
file_path_q_learning <- sprintf("%s/Results/", folder_name_qlearning)

load_dataframe <- function(folder_path, csv_file_name) {
  file_path <- file.path(folder_path, csv_file_name)
  read.csv(file_path)
}

dfs_msf <- list()

dfs_q_learning <- list()

csv_files_msf <- list.files(file_path_msf, pattern = "\\.csv")

csv_files_q_learning <- list.files(file_path_q_learning, pattern = "\\.csv")

for (csv_file in csv_files_msf) {
  df <- load_dataframe(file_path_msf, csv_file)
  dfs_msf[[csv_file]] <- df
}

for (csv_file in csv_files_q_learning) {
  df <- load_dataframe(file_path_q_learning, csv_file)
  dfs_q_learning[[csv_file]] <- df
}

plot_bar_graph_averages(
	dfs_msf,
	dfs_q_learning,
	"lifetime_AA_years",
	"Tempo de Vida em Anos",
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0',
	'lifetime.jpg'
)

plot_bar_graph_averages(
	dfs_msf,
	dfs_q_learning,
	"latency_avg_s",
	"Latência Media",
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0',
	'latencias.jpg'
)

plot_bar_graph_averages(
	dfs_msf,
	dfs_q_learning,
	"join_time_s",
	"Join Time",
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0',
	'join.jpg'
)

plot_bar_graph_averages(
	dfs_msf,
	dfs_q_learning,
	"upstream_reliability",
	"Taxa de Entrega Ponto a Ponto",
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0',
	'taxas_entrega.jpg'
)

plot_boxplots(
	dfs_msf[[1]], 
	dfs_q_learning[[1]], 
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
	paste('lifetime_AA_years', "_boxplot_comparison.jpg", sep = ""),
	'lifetime_AA_years'
)

plot_boxplots(
	dfs_msf[[1]], 
	dfs_q_learning[[1]], 
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
	paste('latency_avg_s', "_boxplot_comparison.jpg", sep = ""),
	'latency_avg_s'
)

plot_boxplots(
	dfs_msf[[1]], 
	dfs_q_learning[[1]], 
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
	paste('join_time_s', "_boxplot_comparison.jpg", sep = ""),
	'join_time_s'
)

plot_boxplots(
	dfs_msf[[1]], 
	dfs_q_learning[[1]], 
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
	paste('upstream_reliability', "_boxplot_comparison.jpg", sep = ""),
	'upstream_reliability'
)
