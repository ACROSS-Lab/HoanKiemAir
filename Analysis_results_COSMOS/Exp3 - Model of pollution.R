library(ggplot2)
library(dplyr)
library(dygraphs)
library(xts)
library(R.utils)

#################################################
# Functions 
#################################################

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

valParam <- function(name,param) {
  l <- strsplit(name, "--")
  l <- lapply(l, function(z) strsplit(z,"-"))
  for(i in 1:length(l[[1]])) {
    if(l[[1]][[i]][1] == param) {
      return(l[[1]][[i]][2])
    }
  }
  return(-1)
}
# val("meanDecay-0.699999988079071--Diffusion-0.019999999552965164","Diffusion")
# val("meanDecay-0.699999988079071--Diffusion-0.019999999552965164","meanDecay")

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

df_from_list_folders_given_value_param <- function(m_folder,nb_steps,col,param,value){
  folders <- list.dirs(m_folder,recursive = FALSE)
  data <- data.frame()
  
  for(f in folders){
    print(f)
    print(valParam(f,param))
    print(value)
    if(valParam(f,param) == value) {
      d <- create_dataframe(f,nb_steps,col)
      
      if(length(data) == 0) {
        data <- data.frame(time=d$time)
      }
      f <- getRelativePath(f, relativeTo = m_folder)
      data[paste("mean",f,sep="")] = d$mean
      data[paste("max",f,sep="")] = d$max
      data[paste("min",f,sep="")] = d$min      
    }
  }
  print(summary(data))
  return(data)
}

df_from_list_folders_given_value_param(main_folder,size_of_csv,col,)

#################################################
# Parse a set of folders to create the dataframe
##

df_from_list_folders <- function(m_folder,nb_steps,col){
  folders <- list.dirs(m_folder,recursive = FALSE)
  data <- data.frame()
  
  for(f in folders){
    d <- create_dataframe(f,nb_steps,col)
    
    if(length(data) == 0) {
      data <- data.frame(time=d$time)
    }
    f <- getRelativePath(f, relativeTo = m_folder)
    data[paste("mean",f,sep="")] = d$mean
    data[paste("max",f,sep="")] = d$max
    data[paste("min",f,sep="")] = d$min
  }
  print(summary(data))
  return(data)
}

#################################################
# Create a plot with confidence interval from df
##

create_dygraphs <- function(df,m_folder,maxRange,n_Y) {
  folders <- list.dirs(m_folder,recursive = FALSE)
  
  p<- dygraph(df)%>%
    dyAxis("y", label = n_Y, valueRange = c(0, maxRange)) 
  # %>%
#    dyLegend(show = "follow")
  
  for(i in 1:length(folders)) {
    f <- getRelativePath(folders[i], relativeTo = m_folder)
    print(paste("mean",f,sep=""))
    p <- p %>%
      dySeries(c(paste("max",f,sep=""),paste("mean",f,sep=""),paste("min",f,sep="")))
  }
  
  return(p)
}



#################################################
## CONSTANTES
#################################################

main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp3"
main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp3-roads"
size_of_csv <- 1500


#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean <- df_from_list_folders(main_folder,size_of_csv,col)

p_mean <- create_dygraphs(df_mean,main_folder,5000,nameY)
p_mean <- create_dygraphs(df_mean,main_folder,600,nameY)
p_mean


#################################################
# STDVAQI : 2
#################################################

nameY = "stdv.AQI"
col <- 2

df_stdDev <- df_from_list_folders(main_folder,size_of_csv,col)

p_stdDev <- create_dygraphs(df_stdDev,main_folder,450
                            ,nameY)
p_stdDev


#################################################
# Mean Max : 4
#################################################

nameY = "Mean Max on interval"
col <- 4

df_meanMax <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMax <- create_dygraphs(df_meanMax,main_folder,7000,nameY)
p_meanMax

#################################################
# Mean Min : 5
#################################################

nameY = "Mean Min on interval"
col <- 5

df_meanMin <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMin <- create_dygraphs(df_meanMin,main_folder,10,nameY)
p_meanMin


##################################################################################################
##################################################################################################
##################################################################################################
main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/Exp3/server8-gridV1"
size_of_csv <- 3000

#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean_Roads <- df_from_list_folders(main_folder,size_of_csv,col)

p_mean_Roads <- create_dygraphs(df_mean_Roads,main_folder,0.05,nameY)
p_mean_Roads




