library(rjson)
library(dplyr)
library(ggplot2)
library(scales)
library(reshape)
library(tidyr)
library(ggthemr)

themename = "fresh"
ggthemr(themename, spacing = 1)
#ggthemr_reset()

# my_color_paletet = c("#ffb3ba","#ffdfba","#ffffba","#baffc9","#bae1ff")
my_color_paletet = c("#168E7F","#65ADC2", "#233B43", "#E84646" ,"#C29365", "#362C21", "#316675","#111111", "#109B37")
# my_color_paletet = c("#E0C8B1", "#F3A2A2", "#B1D5E0", "#233B43", "#909CA0","#D4D4D4", "#316675","#111111", "#109B37")
rainbow_palett <- define_palette(
  swatch = my_color_paletet,
  gradient = c(lower = my_color_paletet[1L], upper = my_color_paletet[2L])
)

ggthemr(rainbow_palett)

plot_boxplots <- function(df_msf, df_q_learning, path_to_save, file_name, metric_name,unidade) {
  
  # Adiciona uma coluna Experimento aos dataframes
  df_msf$Experimento <- "MSF"
  df_q_learning$Experimento <- "Q-Learning"

  # Juntar os dataframes
  df_plot <- rbind(df_msf, df_q_learning)

  # Criar o gráfico de boxplots
  plot_current_graph <- ggplot(df_plot, aes(x = as.factor(Experimento), y = get(metric_name), fill = Experimento)) +
    geom_boxplot(alpha = 0.8) +
    labs(
         x = "Nós",
         y = paste("Média",unidade)) +
    	  theme(legend.position="bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 16, face = 'bold'),
        # axis.text.y = element_text(angle = 35),
        axis.text.x = element_text(size = 16,vjust = .7),
        axis.text.y = element_text(size = 16, angle = 35),
        axis.title = element_text(size = 16), 
        text = element_text(family = 'Times')
  	)  + 
			scale_y_continuous(breaks = pretty_breaks(n = 10)) +
		theme(plot.background = element_rect(fill = "white")) +
    scale_fill_manual(values = c(rgb(51/255, 187/255, 1), rgb(0, 204/255, 153/255)))

  # Salvar o gráfico
  ggsave(file.path(path_to_save, file_name), plot = plot_current_graph, width = 8, height = 6, units = "in", dpi = 300)
}

plot_bar_graph_averages <- function(dfs_msf,dfs_q_learning,column_name,graph_legend,path_to_save,file_name,unidade) {

	create_margin_error_list <- function(stat_result_msf,stat_result_q_learning) {
		margin_error_list <- c()
		for(df_name in names(stat_result_msf)) {
			margin_error_current_df_msf <- stat_result_msf[[df_name]]$margin_error
			margin_error_current_df_qlearning <- stat_result_q_learning[[df_name]]$margin_error
			margin_error_list <- c(margin_error_list,margin_error_current_df_msf,margin_error_current_df_qlearning)
		}
		return(margin_error_list)
	}
	
	calculate_average <- function(dataframes, column_name) {
		results <- list()
		for (dataframe_name in names(dataframes)) {
			current_dataframe_column_data <- dataframes[[dataframe_name]][, column_name]
			mean_data <- mean(current_dataframe_column_data)
			n <- length(current_dataframe_column_data)
			sd_value <- sd(current_dataframe_column_data)
			se <- sd_value / sqrt(n)
			alpha <- 0.01
			freedom <- n - 1
			t_score <- qt(p = alpha / 2, df = freedom, lower.tail = FALSE)
			margin_error <- t_score * se

			result <- list(
				Mean = mean_data,
				margin_error = margin_error
			)
			results[[dataframe_name]] <- result
		}
		return(results)
	}
	result_stat_msf <- calculate_average(dfs_msf, column_name)
	result_stat_qlearning <- calculate_average(dfs_q_learning, column_name)

	df_plot <- data.frame(
		Nos = c(10, 50, 100, 150, 200),
		Media_MSF = sapply(result_stat_msf, function(result) result$Mean),
		Media_Q_Learning = sapply(result_stat_qlearning, function(result) result$Mean)
	)

	df_plot_long <- df_plot %>% pivot_longer(cols = c(Media_MSF, Media_Q_Learning), names_to = "Tipo", values_to = "Media")

	Confidence_Intervals <- create_margin_error_list(result_stat_msf, result_stat_qlearning)
	final_df <-  cbind(df_plot_long,Confidence_Intervals)

	print(final_df)

	plot_current_graph <- ggplot(final_df, aes(x = as.factor(Nos), y = Media, fill = Tipo)) +
	geom_bar(stat = "identity", position = "dodge", color = "white", width = 0.7, alpha = 0.8) +
	geom_errorbar( aes(x=as.factor(Nos), ymin=Media-Confidence_Intervals, ymax=Media+Confidence_Intervals), width=0.4,position = position_dodge(width = 0.7), colour="orange", alpha=0.9, size=1.3) +
	labs(
		x = "Nós",
		y = paste("Média",unidade)) +
	  theme(legend.position="bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 16, face = 'bold'),
        # axis.text.y = element_text(angle = 35),
        axis.text.x = element_text(size = 16,vjust = .7),
        axis.text.y = element_text(size = 16, angle = 35),
        axis.title = element_text(size = 16), 
        text = element_text(family = 'Times')
  	)  +
	scale_y_continuous(breaks = pretty_breaks(n = 10)) +
	theme(plot.background = element_rect(fill = "white")) +
	scale_fill_manual(values = c(rgb(51/255, 187/255, 1), rgb(0, 204/255, 153/255)))

	ggsave(file.path(path_to_save, file_name), plot = plot_current_graph, width = 8, height = 6, units = "in", dpi = 300)
}

setwd("/home/vscardel/q_tsch_simulator/master/bin")


# Solicitar a pasta do experimento
#/home/vscardel/ResultSimExperiments/msfRandomTopologyPredictableBurstResults
#/home/vscardel/ResultSimExperiments/qlearningRandomTopologyPredictableBurstResults
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

#ordena por numero de nos
node_numbers <- as.numeric(gsub("\\D", "", csv_files_msf))
csv_files_msf <- csv_files_msf[order(node_numbers)]

node_numbers <- as.numeric(gsub("\\D", "", csv_files_q_learning))
csv_files_q_learning <- csv_files_q_learning[order(node_numbers)]

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
	'lifetime.jpg',
	'anos'
)

plot_bar_graph_averages(
	dfs_msf,
	dfs_q_learning,
	"latency_avg_s",
	"Latência Media",
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0',
	'latencias.jpg',
	''
)

plot_bar_graph_averages(
	dfs_msf,
	dfs_q_learning,
	"join_time_s",
	"Join Time",
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0',
	'join.jpg',
	'(s)'
)

plot_bar_graph_averages(
	dfs_msf,
	dfs_q_learning,
	"upstream_reliability",
	"Taxa de Entrega Ponto a Ponto",
	'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0',
	'taxas_entrega.jpg',
	''
)

i <- 1
for (num_nodes in c('10', '50', '100', '150', '200')) {
	plot_boxplots(
		dfs_msf[[i]], 
		dfs_q_learning[[i]], 
		'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
		paste('lifetime_AA_years',num_nodes,"_boxplot_comparison.jpg", sep = ""),
		'lifetime_AA_years',
		'anos'
	)

	plot_boxplots(
		dfs_msf[[i]], 
		dfs_q_learning[[i]], 
		'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
		paste('latency_avg_s',num_nodes,"_boxplot_comparison.jpg", sep = ""),
		'latency_avg_s',
		'(s)'
	)

	plot_boxplots(
		dfs_msf[[i]], 
		dfs_q_learning[[i]], 
		'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
		paste('join_time_s',num_nodes, "_boxplot_comparison.jpg", sep = ""),
		'join_time_s',
		'(s)'
	)

	plot_boxplots(
		dfs_msf[[i]], 
		dfs_q_learning[[i]], 
		'/home/vscardel/ResultSimExperiments/Graphs/randomTopologyWithPredictableBurst1.0', 
		paste('upstream_reliability',num_nodes, "_boxplot_comparison.jpg", sep = ""),
		'upstream_reliability',
		''
	)

	i <- i + 1
}

