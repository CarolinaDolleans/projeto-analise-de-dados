library(lubridate)
library(ggplot2)
library(MASS)
library(stats)
library(graphics)
library(plotly)
library(plotly)


###
url = 'https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-states.csv' # passar a url para um objeto
covidBR = read.csv2(url, encoding='latin1', sep = ',') # baixar a base de covidBR

covidPE <- subset(covidBR, state == 'PE') # filtrar para Pernambuco

str(covidPE) # observar as classes dos dados

covidPE$date <- as.Date(covidPE$date, format = "%Y-%m-%d") # modificar a coluna data de string para date

str(covidPE) # observar a mudan�a na classe

covidPE$dia <- seq(1:length(covidPE$date)) # criar um sequencial de dias de acordo com o total de datas para a predi��o

predDia = data.frame(dia = covidPE$dia) # criar vetor auxiliar de predi��o
predSeq = data.frame(dia = seq(max(covidPE$dia)+1, max(covidPE$dia)+180)) # criar segundo vetor auxiliar 

predDia <- rbind(predDia, predSeq) # juntar os dois 

library(drc) # pacote para predi��o

fitLL <- drm(deaths ~ dia, fct = LL2.5(),
             data = covidPE, robust = 'mean') # fazendo a predi��o log-log com a fun��o drm

plot(fitLL, log="", main = "Log logistic") # observando o ajuste

predLL <- data.frame(predicao = ceiling(predict(fitLL, predDia))) # usando o modelo para prever para frente, com base no vetor predDia
predLL$data <- seq.Date(as.Date('2020-03-12'), by = 'day', length.out = length(predDia$dia)) # criando uma sequ�ncia de datas para corresponder aos dias extras na base de predi��o

predLL <- merge(predLL, covidPE, by.x ='data', by.y = 'date', all.x = T) # juntando as informa��es observadas da base original 

library(plotly) # biblioteca para visualiza��o interativa de dados

plot_ly(predLL) %>% 
  add_trace(x = ~ data, y = ~ predicao, type = 'scatter', mode = 'lines', name = "Mortes - Predi��o") %>% 
  add_trace(x = ~ data, y = ~ deaths, name = "Mortes - Observadas", mode = 'lines') %>% 
  layout(title = 'Predi��o de mortes por COVID 19 em Pernambuco', 
         xaxis = list(title = 'Data', showgrid = FALSE), 
         yaxis = list(title = 'Mortes Acumuladas por Dia', showgrid = FALSE),
         hovermode = "compare") # plotando tudo junto, para compara��o

library(zoo) # biblioteca para manipula��o de datas e s�ries temporais

covidPE <- covidPE %>% mutate(new_deaths_sMM7 = round(rollmean(x = deaths, 7, align = "right", fill = NA), 2)) # m�dia m�vel de 7 dias

covidPE <- covidPE %>% mutate(new_deaths_L7 = dplyr::lag(deaths, 7)) # valor defasado em 7 dias

plot_ly(covidPE) %>% 
  add_trace(x = ~ date, y = ~ deaths, type = 'scatter', mode = 'lines', name = "Novas Mortes") %>% 
  add_trace(x = ~ date, y = ~ new_deaths_sMM7, name = "Novas Mortes MM7", mode = 'lines') %>% 
  layout(title = 'Novas Mortes de COVID19 em Pernambuco', 
         xaxis = list(title = 'Data', showgrid = FALSE), 
         yaxis = list(title = 'Novas Mortes por Dia', showgrid = FALSE),
         hovermode = "compare") # plotando tudo junto, para compara��o

library(xts)

(covidPETS <- xts(covidPE$deaths, covidPE$date)) # transformar em ST
str(covidPETS)

autoplot(covidPETS)
acf(covidPETS)
