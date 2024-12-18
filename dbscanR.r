library(ggplot2)
library(dbscan)
library(fpc)
library(factoextra)
library(lubridate)
library(dplyr)
library(gridExtra)
library(daltoolbox)
library(tidyr)


# site com as velocidades máximas das avenidas: https://www.rio.rj.gov.br/dlstatic/10112/6799394/4186011/Radar2017.pdf
data <- read.csv("DBSCAN/output3.csv")
mapa_rj <- data

mapa_rj <- data[sample(nrow(data), size = nrow(data) * 0.1),]

mapa_rj <- mapa_rj %>%
  mutate(
    Rainfall_Normalized = (RAINFALLVOLUME - min(RAINFALLVOLUME, na.rm = TRUE)) / (max(RAINFALLVOLUME, na.rm = TRUE) - min(RAINFALLVOLUME, na.rm = TRUE)),
    Speed_Normalized = (VELOCITY - min(VELOCITY, na.rm = TRUE)) / (max(VELOCITY, na.rm = TRUE) - min(VELOCITY, na.rm = TRUE))
  )

mapa_rj <- mapa_rj %>%
  mutate(
    Indicator = (Rainfall_Normalized) - (Speed_Normalized)
  )

mapa_rj <- mapa_rj %>%
  filter(!is.na(Indicator))

speed <- 20 / 60

data$GPSTIMESTAMP <- as.POSIXct(data$GPSTIMESTAMP, format = "%Y-%m-%d %H:%M:%S")

data$horas <- as.numeric(format(data$GPSTIMESTAMP, "%H"))
data$minutos <- as.numeric(format(data$GPSTIMESTAMP, "%M"))

data$horas_decimal <- data$horas + data$minutos / 60


onibus_congestionados <- data %>%
  filter(horas_decimal >= 17 & horas_decimal <= 18)

onibus_congestionados <- onibus_congestionados[, c("LATITUDE", "LONGITUDE", "horas_decimal", "RAINFALLVOLUME", "RAINFALLZONE", "ADMINISTRATIVEREGION")]

onibus_congestionados <- na.omit(onibus_congestionados)

selected_columns <- onibus_congestionados[, c("LATITUDE", "LONGITUDE", "horas_decimal", "RAINFALLVOLUME")]

selected_columns <- selected_columns %>% drop_na()

selected_columns <- selected_columns[, apply(selected_columns, 2, function(x) length(unique(x)) > 1)]

scaled_datas <- scale(selected_columns)

model <- cluster_dbscan(minPts = 150)

model <- fit(model, scaled_datas)

clu <- cluster(model, scaled_datas)

onibus_congestionados$clusters <- clu

onibus_congestionados <- onibus_congestionados[onibus_congestionados$clusters != 0, ]

ggplot(onibus_congestionados, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters))) +
  geom_point(alpha = 0.5) +
  labs(title = "Clusters dos Ônibus na cidade do Rio de Janeiro",
       x = "Longitude",
       y = "Latitude",
       color = "Cluster") +
  theme_minimal()


# ANALISANDO OS CLUSTERS

onibus_congestionados_summary <- onibus_congestionados %>%
  group_by(clusters) %>%
  summarise(
    Media_Lat = mean(LATITUDE, na.rm = TRUE),
    Media_Log = mean(LONGITUDE, na.rm = TRUE),
    Media_Chuva = mean(RAINFALLVOLUME, na.rm = TRUE),
    Contagem = n()
  )

ggplot() +
  # Primeira camada de pontos em cinza
  geom_point(data = mapa_rj, aes(x = LONGITUDE, y = LATITUDE), color = "gray", alpha = 0.5) +
  
  # Segunda camada com os clusters
  geom_point(data = onibus_congestionados, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters)), alpha = 0.5) +
  
  # Personalização dos rótulos e títulos
  labs(
    title = "Clusters pelo Rio de Janeiro",
    x = "Longitude",
    y = "Latitude",
    color = "Cluster"
  ) +
  
  # Tema minimalista
  theme_minimal() +
  
  # Ajustes adicionais de estilo
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "right"  # Manter a legenda para os clusters
  )


ggplot(mapa_rj, aes(x = LONGITUDE, y = LATITUDE)) +
  geom_point(color = "gray", alpha = 0.5) + # Definir pontos em cinza
  labs(
    title = "Clusters pelo Rio de Janeiro",
    x = "Longitude",
    y = "Latitude"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "none" # Remover a legenda dos clusters cinza
  ) +
  geom_point(data = onibus_congestionados_summary, aes(x = Media_Log, y = Media_Lat, color = as.factor(Contagem), size = Contagem), alpha = 0.5) +
  labs(color = "Indicador", size = "Indicador")


# Ilha do governador

ilha_governador <- data[data$ADMINISTRATIVEREGION == 20,]

ilha_governador <- ilha_governador[!is.na(ilha_governador$LATITUDE) & !is.na(ilha_governador$LONGITUDE), ]

onibus_ilha <- onibus_congestionados[onibus_congestionados$ADMINISTRATIVEREGION == 20,]

ggplot() +
  # Primeira camada de pontos em cinza
  geom_point(data = ilha_governador, aes(x = LONGITUDE, y = LATITUDE), color = "gray", alpha = 0.5) +
  
  # Segunda camada com os clusters
  geom_point(data = onibus_ilha, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters)), alpha = 0.5) +
  
  # Personalização dos rótulos e títulos
  labs(
    title = "Clusters pela Ilha do Governador",
    x = "Longitude",
    y = "Latitude",
    color = "Cluster"
  ) +
  
  # Tema minimalista
  theme_minimal() +
  
  # Ajustes adicionais de estilo
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "right"  # Manter a legenda para os clusters
  )

# Campo grande - Coordenada: -22.901788, -43.556432

campo_grande <- data[data$ADMINISTRATIVEREGION == 18,]

campo_grande <- campo_grande[!is.na(campo_grande$LATITUDE) & !is.na(campo_grande$LONGITUDE), ]

onibus_campo_grande <- onibus_congestionados[onibus_congestionados$ADMINISTRATIVEREGION == 18,]

ggplot() +
  # Primeira camada de pontos em cinza
  geom_point(data = campo_grande, aes(x = LONGITUDE, y = LATITUDE), color = "gray", alpha = 0.5) +
  
  # Segunda camada com os clusters
  geom_point(data = onibus_campo_grande, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters)), alpha = 0.5) +
  
  # Personalização dos rótulos e títulos
  labs(
    title = "Clusters por Campo Grande",
    x = "Longitude",
    y = "Latitude",
    color = "Cluster"
  ) +
  
  # Tema minimalista
  theme_minimal() +
  
  # Ajustes adicionais de estilo
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "right"  # Manter a legenda para os clusters
  )

# Centro

centro <- data[data$ADMINISTRATIVEREGION == 2,]

centro <- centro[!is.na(centro$LATITUDE) & !is.na(centro$LONGITUDE), ]

onibus_centro <- onibus_congestionados[onibus_congestionados$ADMINISTRATIVEREGION == 2,]

ggplot() +
  # Primeira camada de pontos em cinza
  geom_point(data = centro, aes(x = LONGITUDE, y = LATITUDE), color = "gray", alpha = 0.5) +
  
  # Segunda camada com os clusters
  geom_point(data = onibus_centro, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters)), alpha = 0.5) +
  
  # Personalização dos rótulos e títulos
  labs(
    title = "Clusters pelo Centro",
    x = "Longitude",
    y = "Latitude",
    color = "Cluster"
  ) +
  
  # Tema minimalista
  theme_minimal() +
  
  # Ajustes adicionais de estilo
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "right"  # Manter a legenda para os clusters
  )

# Pegando a Rua Riachuelo como exemplo, sendo a velocidade máxima dela 50km/h. Num horário de 17hrs de um dia útil um trajeto de 1.4km demora entre 4 a 12 minutos. O que deveria ser no máximo 1 minuto e 40 segundos

# Penha

penha <- data[data$ADMINISTRATIVEREGION == 11,]

penha <- penha[!is.na(penha$LATITUDE) & !is.na(penha$LONGITUDE), ]

onibus_penha <- onibus_congestionados[onibus_congestionados$ADMINISTRATIVEREGION == 11,]

ggplot() +
  # Primeira camada de penha em cinza
  geom_point(data = penha, aes(x = LONGITUDE, y = LATITUDE), color = "gray", alpha = 0.5) +
  
  # Segunda camada com os clusters
  geom_point(data = onibus_penha, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters)), alpha = 0.5) +
  
  # Personalização dos rótulos e títulos
  labs(
    title = "Clusters pela Penha",
    x = "Longitude",
    y = "Latitude",
    color = "Cluster"
  ) +
  
  # Tema minimalista
  theme_minimal() +
  
  # Ajustes adicionais de estilo
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "right"  # Manter a legenda para os clusters
  )

# Ramos

ramos <- data[data$ADMINISTRATIVEREGION == 10,]

ramos <- ramos[!is.na(ramos$LATITUDE) & !is.na(ramos$LONGITUDE), ]

onibus_ramos <- onibus_congestionados[onibus_congestionados$ADMINISTRATIVEREGION == 10,]

ggplot() +
  # Primeira camada de ramos em cinza
  geom_point(data = ramos, aes(x = LONGITUDE, y = LATITUDE), color = "gray", alpha = 0.5) +
  
  # Segunda camada com os clusters
  geom_point(data = onibus_ramos, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters)), alpha = 0.5) +
  
  # Personalização dos rótulos e títulos
  labs(
    title = "Clusters por Ramos",
    x = "Longitude",
    y = "Latitude",
    color = "Cluster"
  ) +
  
  # Tema minimalista
  theme_minimal() +
  
  # Ajustes adicionais de estilo
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "right"  # Manter a legenda para os clusters
  )

# Lagoa

lagoa <- data[data$ADMINISTRATIVEREGION == 6,]

lagoa <- lagoa[!is.na(lagoa$LATITUDE) & !is.na(lagoa$LONGITUDE), ]

onibus_lagoa <- onibus_congestionados[onibus_congestionados$ADMINISTRATIVEREGION == 6,]

ggplot() +
  # Primeira camada de lagoa em cinza
  geom_point(data = lagoa, aes(x = LONGITUDE, y = LATITUDE), color = "gray", alpha = 0.5) +
  
  # Segunda camada com os clusters
  geom_point(data = onibus_lagoa, aes(x = LONGITUDE, y = LATITUDE, color = as.factor(clusters)), alpha = 0.5) +
  
  # Personalização dos rótulos e títulos
  labs(
    title = "Clusters pela Lagoa",
    x = "Longitude",
    y = "Latitude",
    color = "Cluster"
  ) +
  
  # Tema minimalista
  theme_minimal() +
  
  # Ajustes adicionais de estilo
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "right"  # Manter a legenda para os clusters
  )

