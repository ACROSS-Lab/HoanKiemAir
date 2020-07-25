# Libraries
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


################################################################  
################################  exp61

#################################################
## CONSTANTES
#################################################

main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp61"
size_of_csv <- 3000


#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean <- df_from_list_folders(main_folder,size_of_csv,col)

p_mean <- create_dygraphs(df_mean,main_folder,220,nameY)
p_mean


#################################################
# STDVAQI : 2
#################################################

nameY = "stdv.AQI"
col <- 2

df_stddev <- df_from_list_folders(main_folder,size_of_csv,col)

p_stddev <- create_dygraphs(df_stddev,main_folder,60,nameY)
p_stddev


#################################################
# Mean Max : 4
#################################################

nameY = "Mean Max on interval"
col <- 4

df_meanMax <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMax <- create_dygraphs(df_meanMax,main_folder,500,nameY)
p_meanMax

#################################################
# Mean Min : 5
#################################################

nameY = "Mean Min on interval"
col <- 5

df_meanMin <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMin <- create_dygraphs(df_meanMin,main_folder,15,nameY)
p_meanMin




################################################################  
################################  exp62

#################################################
## CONSTANTES
#################################################

main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp62"
size_of_csv <- 3000


#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean <- df_from_list_folders(main_folder,size_of_csv,col)

p_mean <- create_dygraphs(df_mean,main_folder,100,nameY)
p_mean


#################################################
# STDVAQI : 2
#################################################

nameY = "stdv.AQI"
col <- 2

df_stddev <- df_from_list_folders(main_folder,size_of_csv,col)

p_stddev <- create_dygraphs(df_stddev,main_folder,50,nameY)
p_stddev


#################################################
# Mean Max : 4
#################################################

nameY = "Mean Max on interval"
col <- 4

df_meanMax <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMax <- create_dygraphs(df_meanMax,main_folder,250,nameY)
p_meanMax

#################################################
# Mean Min : 5
#################################################

nameY = "Mean Min on interval"
col <- 5

df_meanMin <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMin <- create_dygraphs(df_meanMin,main_folder,10,nameY)
p_meanMin


################################################################  
################################  exp63

#################################################
## CONSTANTES
#################################################

main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp63"
size_of_csv <- 3000


#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean <- df_from_list_folders(main_folder,size_of_csv,col)

p_mean <- create_dygraphs(df_mean,main_folder,220,nameY)
p_mean


#################################################
# STDVAQI : 2
#################################################

nameY = "stdv.AQI"
col <- 2

df_stddev <- df_from_list_folders(main_folder,size_of_csv,col)

p_stddev <- create_dygraphs(df_stddev,main_folder,60,nameY)
p_stddev


#################################################
# Mean Max : 4
#################################################

nameY = "Mean Max on interval"
col <- 4

df_meanMax <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMax <- create_dygraphs(df_meanMax,main_folder,520,nameY)
p_meanMax

#################################################
# Mean Min : 5
#################################################

nameY = "Mean Min on interval"
col <- 5

df_meanMin <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMin <- create_dygraphs(df_meanMin,main_folder,15,nameY)
p_meanMin


################################################################  
################################  exp64

#################################################
## CONSTANTES
#################################################

main_folder <- "~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp64"
size_of_csv <- 3000


#################################################
# MEANAQI : 1
#################################################

nameY <- "Mean.AQI"
col <- 1

df_mean <- df_from_list_folders(main_folder,size_of_csv,col)

p_mean <- create_dygraphs(df_mean,main_folder,100,nameY)
p_mean

#################################################
# STDVAQI : 2
#################################################

nameY = "stdv.AQI"
col <- 2

df_stddev <- df_from_list_folders(main_folder,size_of_csv,col)

p_stddev <- create_dygraphs(df_stddev,main_folder,50,nameY)
p_stddev


#################################################
# Mean Max : 4
#################################################

nameY = "Mean Max on interval"
col <- 4

df_meanMax <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMax <- create_dygraphs(df_meanMax,main_folder,250,nameY)
p_meanMax

#################################################
# Mean Min : 5
#################################################

nameY = "Mean Min on interval"
col <- 5

df_meanMin <- df_from_list_folders(main_folder,size_of_csv,col)

p_meanMin <- create_dygraphs(df_meanMin,main_folder,5,nameY)
p_meanMin

