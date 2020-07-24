## Experiment 1
## The objective of this experiment is to find 
##  - the number of steps for 1 simulation to stop simulations
##  - indicators to evaluate this simulation (a mean over the last N steps ) --> find N
##  - the number of replications needed
## For all these cases, we use the standard error.
##
######
## Other important information: when considering the interactive simulation:
##  - the number of steps to reach a quite stable state


###############################################################################
# Step 1. Compute the standard error (on each of the 4 columns) on a given file 
# to determine a limit simulation step.
###############################################################################

plot_standard_error <- function(path,col) {
  results <- read.csv2(path,sep=",",header = T)
  # values = results$Mean.AQI
  values = results[,col]
  
  # collect cumulative stats
  std_errors = c()
  for(i in 2:length(values)) {
    data <- values[0:i]
    stderr <- sd(data) / sqrt(length(data))
    std_errors <- c(std_errors,stderr) 
  }
  
  # line plot of cumulative values
  plot(std_errors,type="l",xlab="nb steps",ylab=names(results)[col]) 
}

draw_lines <-function() {
  abline(v=1000,col="red")
  abline(v=2000,col="red")
  abline(v=3000,col="red")
  abline(v=4000,col="red")
  abline(v=5000,col="red")
}

## Plot for one file 
m<-matrix(c(1,2,3,4),ncol=2,byrow=TRUE)
layout(m)
plot_standard_error('res3.0.csv',1)
abline(h=5,col="green")
abline(h=10,col="red")
draw_lines()
plot_standard_error('res3.0.csv',2)
draw_lines()
abline(h=2,col="red")
abline(h=1,col="green")
plot_standard_error('res3.0.csv',3)
draw_lines()
abline(h=40000,col="red")
abline(h=20000,col="green")
plot_standard_error('res3.0.csv',4)
draw_lines()
abline(h=10,col="red")
abline(h=5,col="green")

## Plot for another file 
m<-matrix(c(1,2,3,4),ncol=2,byrow=TRUE)
layout(m)
plot_standard_error('tests10/res3.0.csv',1)
abline(h=5,col="green")
abline(h=10,col="red")
draw_lines()
plot_standard_error('tests10/res3.0.csv',2)
draw_lines()
abline(h=2,col="red")
abline(h=1,col="green")
plot_standard_error('tests10/res3.0.csv',3)
draw_lines()
abline(h=40000,col="red")
abline(h=20000,col="green")
plot_standard_error('tests10/res3.0.csv',4)
draw_lines()
abline(h=10,col="red")
abline(h=5,col="green")


###############################################################################
# Result Step 1. Find N such that the mean on the last N values is a good indicator.
###############################################################################
stableStep <- 2000
finalStep <- 2998


###############################################################################
# Step 2. Find N such that the mean on the last N values is a good indicator.
###############################################################################

standard_error_on_replication <- function(sst,fst,col) {
  # Import data
  temp = list.files(pattern="*.csv")
  #temp
  myfiles = lapply(temp, function(x) read.csv2(x,sep=",",header = T))
  myfiles <- sample(myfiles)

  # collect cumulative stats
  std_errors = c()
  for(i in 2:length(myfiles)) {
    data <- unlist(lapply(myfiles[1:i], function(x) mean(as.numeric(x[sst:fst,col]))))
#    data <- unlist(lapply(sample(myfiles)[1:i], function(x) mean(as.numeric(x[sst:fst,col]))))

    stderr <- sd(data) / sqrt(length(data))
#    print(stderr)
    std_errors <- c(std_errors,stderr) 
  }
#  print(length(std_errors))
#  print(std_errors)
  # line plot of cumulative values
  plot(std_errors,type="l",xlab="nb replications",ylab=names(results)[col]) 
}

m<-matrix(c(1,2,3,4),ncol=2,byrow=TRUE)
layout(m)

standard_error_on_replication(stableStep,finalStep,1)
standard_error_on_replication(stableStep,finalStep,2)
standard_error_on_replication(stableStep,finalStep,3)
standard_error_on_replication(stableStep,finalStep,4)

m<-matrix(c(1,2,3),ncol=3,byrow=TRUE)
layout(m)

standard_error_on_replication(stableStep,finalStep,1)
standard_error_on_replication(stableStep,finalStep,2)
#standard_error_on_replication(stableStep,finalStep,3)
standard_error_on_replication(stableStep,finalStep,4)






# 
# tba_Res[1] <- read.csv2("res0.25242825755510856.csv",sep=",",header = T)

###############################################################################
# load results file
#results <- read.csv2('res1.0.csv',sep=",",nrows=5,header = T)
# results <- read.csv2('res1.0.csv',sep=",",header = T)

plot_standard_error <- function(path,col) {
  results <- read.csv2(path,sep=",",header = T)
  # values = results$Mean.AQI
  values = results[,col]
  
  # collect cumulative stats
  std_errors = c()
  for(i in 2:length(values)) {
    data <- values[0:i]
    stderr <- sd(data) / sqrt(length(data))
    std_errors <- c(std_errors,stderr) 
  }
  
  # line plot of cumulative values
  plot(std_errors,type="l",xlab="nb steps",ylab=names(results)[col]) 
}




standard_error_on_replication <- function(sst,fst,col) {
  # Import data
  temp = list.files(pattern="*.csv")
  myfiles = lapply(temp, function(x) read.csv2(x,sep=",",header = T))
  myfiles <- sample(myfiles)
  
  # collect cumulative stats
  std_errors = c()
  for(i in 2:length(myfiles)) {
    data <- unlist(lapply(myfiles[1:i], function(x) mean(as.numeric(x[sst:fst,col]))))
    stderr <- sd(data) / sqrt(length(data))
    std_errors <- c(std_errors,stderr) 
  }
  
  # line plot of cumulative values
  plot(std_errors,type="l",xlab="nb replications",ylab=names(myfiles[[1]])[col]) 
}


draw_lines <-function() {
  abline(v=1000,col="red")
  abline(v=2000,col="red")
  abline(v=3000,col="red")
  abline(v=4000,col="red")
  abline(v=5000,col="red")
}

m<-matrix(c(1,2,3,4),ncol=2,byrow=TRUE)
layout(m)
plot_standard_error('res3.0.csv',1)
abline(h=5,col="green")
abline(h=10,col="red")
draw_lines()
plot_standard_error('res3.0.csv',2)
draw_lines()
abline(h=2,col="red")
abline(h=1,col="green")
plot_standard_error('res3.0.csv',3)
draw_lines()
abline(h=40000,col="red")
abline(h=20000,col="green")
plot_standard_error('res3.0.csv',4)
draw_lines()
abline(h=10,col="red")
abline(h=5,col="green")

m<-matrix(c(1,2,3,4),ncol=2,byrow=TRUE)
layout(m)
plot_standard_error('tests10/res3.0.csv',1)
abline(h=5,col="green")
abline(h=10,col="red")
draw_lines()
plot_standard_error('tests10/res3.0.csv',2)
draw_lines()
abline(h=2,col="red")
abline(h=1,col="green")
plot_standard_error('tests10/res3.0.csv',3)
draw_lines()
abline(h=40000,col="red")
abline(h=20000,col="green")
plot_standard_error('tests10/res3.0.csv',4)
draw_lines()
abline(h=10,col="red")
abline(h=5,col="green")