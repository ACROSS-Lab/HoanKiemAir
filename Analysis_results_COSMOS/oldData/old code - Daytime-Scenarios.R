# Libraries
library(ggplot2)
library(dplyr)
library(dygraphs)
library(xts)

#################################################
# Functions 
#################################################

# open_csv <- function(path) read.csv2(path,sep=",",nrows=10,header = T)
open_csv <- function(path) read.csv2(path,sep=",",header = T)

max_line_col <- function(d,i,col) {
  x <- lapply(d, function(x) x[i,col])
  return(max(unlist(x)))
}

min_line_col <- function(d,i,col) {
  x <- lapply(d, function(x) x[i,col])
  return(min(unlist(x)))
}

mean_line_col <- function(d,i,col) {
  x <- lapply(d, function(x) x[i,col])
  return(mean(as.numeric(unlist(x))))
}

#################################################
# Import data 
#################################################

#################################################
# Create a dataframe from a single folder
##

create_dataframe <- function(wd,size_csv,col) { #col) {
  
  print(wd)
  setwd(wd)
  
  # Import data
  temp = list.files(pattern="*.csv")
  myfiles = lapply(temp, function(x) open_csv(x))
  #  size_csv <- length((myfiles[[1]])[,1])
  nb_elements <- 1:size_csv    
  
  max <- lapply(nb_elements,function(ind) max_line_col(myfiles,ind,col))
  min  <- lapply(nb_elements,function(ind) min_line_col(myfiles,ind,col))
  mean  <- lapply(nb_elements,function(ind) mean_line_col(myfiles,ind,col))
  
  data <- data.frame(
    time=nb_elements, 
    "mean"=unlist(mean),
    "max"=unlist(max), 
    "min"=unlist(min)
  )
  
  return(data)
}


#################################################
# Parse a set of folders to create the dataframe
##

df_from_list_folders <- function(m_folder,folders,nb_steps,col){
  data <- data.frame()
  
  for(f in folders){
    d <- create_dataframe(paste(m_folder,f,sep="/"),nb_steps,col)
    
    if(length(data) == 0) {
      data <- data.frame(time=d$time)
    }
    data[paste("mean",f,sep="")] = d$mean
    data[paste("max",f,sep="")] = d$max
    data[paste("min",f,sep="")] = d$min
  }
  return(data)
}

#################################################
# Create a plot with confidence interval from df
##

create_dygraphs <- function(df,folders,maxRange,n_Y) {
  p<- dygraph(df)%>%
    dyAxis("y", label = n_Y, valueRange = c(0, maxRange)) %>%
    dyLegend(show = "follow")
  
  for(i in 1:length(folders)) {
    f <- list_of_folders[i]
    print(paste("mean",f,sep=""))
    p <- p %>%
      dySeries(c(paste("max",f,sep=""),paste("mean",f,sep=""),paste("min",f,sep="")))
  }
  
  return(p)
}

#################################################
## CONSTANTES
#################################################

main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/Daytime-scenarios"
list_of_folders <- c("0","1","2")
size_of_csv <- 3000


#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_mean <- create_dygraphs(df_mean,list_of_folders,140000,nameY)
p_mean


#################################################
# STDDEV : 2
#################################################

nameY <- "StdDev.AQI"
col <- 2

df_stdDev <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_stdDev <- create_dygraphs(df_stdDev,list_of_folders,75000,nameY)
p_stdDev

#################################################
# MeanMax : 4
#################################################

nameY <- "MeanMax.AQI"
col <- 4

df_meanMax <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_meanMax <- create_dygraphs(df_meanMax,list_of_folders,550000,nameY)
p_meanMax

#################################################
# meanMin : 5
#################################################

nameY <- "MeanMin.AQI"
col <- 5

df_meanMin <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_meanMin <- create_dygraphs(df_meanMin,list_of_folders,18000,nameY)
p_meanMin



##################################################################################################
##################################################################################################
# Study of scenario evolution impact
##################################################################################################
##################################################################################################

#################################################
## CONSTANTES
#################################################

main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/Daytime-evolutions-scenarios"
list_of_folders <- c("Scenario1","Scenario2")
size_of_csv <- 3000


#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_mean <- create_dygraphs(df_mean,list_of_folders,140000,nameY)
p_mean


#################################################
# STDDEV : 2
#################################################

nameY <- "StdDev.AQI"
col <- 2

df_stdDev <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_stdDev <- create_dygraphs(df_stdDev,list_of_folders,45000,nameY)
p_stdDev

#################################################
# MeanMax : 4
#################################################

nameY <- "MeanMax.AQI"
col <- 4

df_meanMax <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_meanMax <- create_dygraphs(df_meanMax,list_of_folders,450000,nameY)
p_meanMax

#################################################
# meanMin : 5
#################################################

nameY <- "MeanMin.AQI"
col <- 5

df_meanMin <- df_from_list_folders(main_folder,list_of_folders,size_of_csv,col)

p_meanMin <- create_dygraphs(df_meanMin,list_of_folders,18000,nameY)
p_meanMin

