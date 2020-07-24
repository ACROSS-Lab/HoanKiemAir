# Libraries
library(ggplot2)
library(dplyr)
library(dygraphs)
library(xts)

setwd("~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp11/")

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

# Import data
temp = list.files(pattern="*.csv")
#temp
myfiles = lapply(temp, function(x) open_csv(x))
#myfiles
size_csv <- length((myfiles[[1]])[,1])

nb_elements <- 1:size_csv

##################################################################################################
##################################################################################################
# Step 1: 
#    GOAL: find the number of steps
##################################################################################################
##################################################################################################

#################################################
# MeanAQI : 1
#################################################
nameY = "Mean.AQI"
col <- 1
max <- lapply(nb_elements,function(ind) max_line_col(myfiles,ind,col))
#unlist(max)
min  <- lapply(nb_elements,function(ind) min_line_col(myfiles,ind,col))
#unlist(min)
mean  <- lapply(nb_elements,function(ind) mean_line_col(myfiles,ind,col))
#unlist(mean)

data <- data.frame(
  time=nb_elements, 
  mean=unlist(mean),
  max=unlist(max), 
  min=unlist(min)
)

# dyAxis("y", label = nameY, valueRange = c(0, 1700)) %>%
p <- dygraph(data) %>%
  dyAxis("y", label = nameY, valueRange = c(0, 100)) %>%
  dySeries(c("max","mean","min"))
p


#################################################
# STDVAQI : 2
#################################################

nameY = "stdv.AQI"
col <- 2
max <- lapply(nb_elements,function(ind) max_line_col(myfiles,ind,col))
#unlist(max)
min  <- lapply(nb_elements,function(ind) min_line_col(myfiles,ind,col))
#unlist(min)
mean  <- lapply(nb_elements,function(ind) mean_line_col(myfiles,ind,col))
#unlist(mean)

data <- data.frame(
  time=nb_elements, 
  mean=unlist(mean),
  max=unlist(max), 
  min=unlist(min)
)

#   dyAxis("y", label = nameY, valueRange = c(0, 600)) %>%
p <- dygraph(data) %>%
  dyAxis("y", label = nameY, valueRange = c(0, 50)) %>%
  dySeries(c("max","mean","min"))
p

#################################################
# MAX.AQI : 4
#################################################

nameY = "MAX.AQI"
col <- 4
max <- lapply(nb_elements,function(ind) max_line_col(myfiles,ind,col))
#unlist(max)
min  <- lapply(nb_elements,function(ind) min_line_col(myfiles,ind,col))
#unlist(min)
mean  <- lapply(nb_elements,function(ind) mean_line_col(myfiles,ind,col))
#unlist(mean)

data <- data.frame(
  time=nb_elements, 
  mean=unlist(mean),
  max=unlist(max), 
  min=unlist(min)
)

p <- dygraph(data) %>%
  dyAxis("y", label = nameY, valueRange = c(0, 200)) %>%
  dySeries(c("max","mean","min"))
p


#################################################
# MIN.AQI : 5
#################################################

nameY = "Mean Min on interval"
col <- 5
max <- lapply(nb_elements,function(ind) max_line_col(myfiles,ind,col))
#unlist(max)
min  <- lapply(nb_elements,function(ind) min_line_col(myfiles,ind,col))
#unlist(min)
mean  <- lapply(nb_elements,function(ind) mean_line_col(myfiles,ind,col))
#unlist(mean)

data <- data.frame(
  time=nb_elements, 
  mean=unlist(mean),
  max=unlist(max), 
  min=unlist(min)
)

#    dyAxis("y", label = nameY, valueRange = c(0, 3000)) %>%
p <- dygraph(data) %>%
  dyAxis("y", label = nameY, valueRange = c(0, 20)) %>%
  dySeries(c("max","mean","min"))
p

##################################################################################################
# Result Step 1. Find N such that the mean on the last N values is a good indicator.
##################################################################################################
stableStep <- 2000
finalStep <- 2998
setwd("~/Dev/GitRepository/HoanKiemAir/Analysis_results_COSMOS/exp12/")



##################################################################################################
##################################################################################################
# Step 2: 
#    GOAL: define a "good" indicator
##################################################################################################
##################################################################################################

# The function will be the average over the last 1000 steps of the mean AQI:
#  function(x) mean(as.numeric(x[sst:fst,col]))))


##################################################################################################
##################################################################################################
# Step 3: 
#    GOAL: compute the needed number of replications
##################################################################################################
##################################################################################################

standard_error_on_replication <- function(sst,fst,col) {
  # Import data
  temp = list.files(pattern="*.csv")
  myfiles = lapply(temp, function(x) read.csv2(x,sep=",",header = T))
  myfiles <- sample(myfiles)
  
  # collect cumulative stats
  std_errors = c()
  for(i in 2:length(myfiles)) {
    
    # to collect over the 10 tries for 1 given number of replications i
    i_std_errors <-c()
    
    for(j in 1:10) {
      myfiles <- sample(myfiles)
      data <- unlist(lapply(myfiles[1:i], function(x) mean(as.numeric(x[sst:fst,col]))))
      stderr <- sd(data) / sqrt(length(data))
      i_std_errors <- c(i_std_errors,stderr) 
    }
    
    std_errors <- c(std_errors,mean(i_std_errors)) 
  }
  
  # line plot of cumulative values
  plot(std_errors,type="l",xlab="number of replications",ylab=names(myfiles[[1]])[col]) 
}



m<-matrix(c(1,2,3,4),ncol=4,byrow=TRUE)
layout(m)

standard_error_on_replication(stableStep,finalStep,1)
standard_error_on_replication(stableStep,finalStep,2)
#standard_error_on_replication(stableStep,finalStep,3)
standard_error_on_replication(stableStep,finalStep,4)
standard_error_on_replication(stableStep,finalStep,5)

