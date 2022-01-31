# PSMSL Tide Data
library(lubridate)
library(data.table)

# Individual File Reading 
# Read the gauge file list (location, names)
file_list = read.csv("/Users/mupton/Dropbox/My Mac (GE-LAP-885.local)/Downloads/rlr_annual/filelist.txt",stringsAsFactors = FALSE, header=F,sep=";")
colnames(file_list)<- c("id","latitude","longitude","name","coastline","stationcode","stationflag")

# Read 1x data set - oldest station with 1807 start date (sets the initial date)
data = read.csv("/Users/mupton/Dropbox/My Mac (GE-LAP-885.local)/Downloads/rlr_annual/data/1.rlrdata",stringsAsFactors = FALSE, header=F,sep=";")
data$V2[data$V2 == -99999] <- NA
names = c("Date","Tidal_Level","flag_attention_1","flag_attention_2")
colnames(data) = names
head(data)

# Convert decimal date to R date using lubridate function
# Date format = year + (month-0.5)/12.0
data$Date = date_decimal(data$Date) 
plot(data$Date,data$Tidal_Level,type="b")

# Loop to join the data by common date - shall take the average value across all tidal gauges 
# Loop through the directory

# Set initial data frame 
df = data.frame(data$Date)
colnames(df) = "Date"
head(df)

path = "/Users/mupton/Dropbox/My Mac (GE-LAP-885.local)/Downloads/rlr_annual/data"
out.file<-""
file.names <- dir(path, pattern =".rlrdata")
i=1
head(file_list)
for(i in 1:length(file.names)){
  file <- read.csv(paste0("/Users/mupton/Dropbox/My Mac (GE-LAP-885.local)/Downloads/rlr_annual/data/",
                          file.names[i]),stringsAsFactors = FALSE, header=F,sep=";")
  file$V2[file$V2 == -99999] <- NA
  file$V1 = date_decimal(file$V1)
  new_df = data.frame(file$V1,file$V2)
  #names = c("Date",paste0("Tide_Level_",file_list[i,4]),paste0("flag_1",file_list[i,4]),paste0("flag_2",file_list[i,4]))
  names = c("Date",paste0("Tide_Level_",file_list[i,4]))
  colnames(new_df) = names
  head(new_df)
  setDT(df)
  setDT(new_df)
  df = new_df[df, on = c('Date')]
  cat("this is iteration",i,"\n")
}

# Perform Row Means 
row_mean_df = df[1:nrow(df),2:length(df)]
row_mean <- rowMeans(row_mean_df, na.rm=TRUE)
final = data.frame(df$Date,row_mean)
colnames(final) = c("Date","World_Wide_Mean")
head(final)

# Standard Plot
plot(df$Date,row_mean,type="b")
final$na_count <- apply(!is.na(row_mean_df), 1, sum)
plot(df$Date,row_mean_df$na_count,type="l")

str(final)
# Tidal data plot 
library(ggplot2)
library(scales)
p1 = ggplot(data = final, aes(x=Date,y=World_Wide_Mean,col=World_Wide_Mean)) +
  geom_point(color="red")+
  geom_line(color="red")+
  theme_bw()+
  ggtitle("Mean Sea Level")+
  ylab("Annual Monthly Mean - All RLR Stations")+
  xlab("Date")+
  #scale_y_continuous(breaks = seq(0, max(final$World_Wide_Mean), by = 100))+
  labs(caption = "Data Source: Permanent Service for Mean Sea Level")+
# scale_x_date(breaks = date_breaks("year"), 
#             labels=date_format(format = "%YYYY", tz = "UTC"))
#scale_x_date(date_breaks = "year")+
labs(colour="Bedroom Size")
p1

p2 = ggplot(data = final, aes(x=Date,y=na_count,col=World_Wide_Mean)) +
  geom_line(color="red")+
  theme_bw()+
  ggtitle("Total Stations")+
  ylab("#No. Stations")+
  xlab("Date")#+
 # scale_y_continuous(breaks = seq(0, max(final$World_Wide_Mean), by = 100))
p2



# Seasonal Component subset all data North and South Hemisphere 




#----Test Reading Matlab files into R
library(R.matlab)
library(tidyverse)
annual_tide_gauge <- readMat("/Users/mupton/Dropbox/My Mac (GE-LAP-885.local)/Downloads/test_tidal_df.mat")
str(annual_tide_gauge)
annual_tide_gauge_data <- lapply(annual_tide_gauge, unlist, use.names=FALSE)
annual_tide_gauge_df <- as.data.frame(annual_tide_gauge_data) # now has correct number of obs and vars
annual_tide_gauge_df_pivot <- annual_tide_gauge_df %>% pivot_longer(everything())
site_1<-df[,1]
