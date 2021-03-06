##----------Updated PSMSL Tide Data Code-----------
#--Monthly Data---
rm(list = ls())
# Set Directory
setwd("/Users/mupton/Desktop/Github/tide_gauge_data_PSMSL")
library(tidyverse)
library(data.table)

###------Individual File Reading Test-------
# Read the gauge file list (location, names)
file_list <- read.csv("rlr_monthly/filelist.txt",stringsAsFactors = FALSE, header=F,sep=";")
colnames(file_list)<- c("id","latitude","longitude","name","coastline","stationcode","stationflag")
# Removing white space in the name of each site
file_list$name <- gsub("[[:space:]]", "",file_list$name)
file_list$stationflag <- gsub("[[:space:]]", "",file_list$stationflag)

# Read 1st data set - oldest station with 1807 start date (sets the initial date)
site_1 <- read.csv("rlr_monthly/data/1.rlrdata",stringsAsFactors = FALSE, header=F,sep=";")
site_1$V2[site_1$V2 == -99999] <- NA
site_1$id <- "1"
#--What is flag_attention_2?---
colnames(site_1) = c("Age","RSL","flag_attention_1","flag_attention_2","id")
# Combining file list (location,names) with the SL vs Age data for site 1
full_site_1_df <- merge(site_1,file_list[1,])

# Read 2nd data set
site_2 <- read.csv("rlr_monthly/data/10.rlrdata",stringsAsFactors = FALSE, header=F,sep=";")
site_2$V2[site_2$V2 == -99999] <- NA
site_2$id <- "2"
colnames(site_2) <- c("Age","RSL","flag_attention_1","flag_attention_2","id")
# Combining file list (location,names) with the SL vs Age data for site 2
full_site_2_df <- merge(site_2,file_list[2,])

#--Joining site 1 & 2---
SL_df_site_1_2<- rbind(full_site_1_df,full_site_2_df)
#--Remove NAs--
SL_df_site_1_2<- SL_df_site_1_2 %>%  drop_na()
#-- Removing sites which have a station flag raised as they are poor sites---
SL_df_site_1_2 <- SL_df_site_1_2 %>%  filter(!stationflag == "Y")

#---Averaging monthly RSL values---
SL_df_site_1_2_average <- SL_df_site_1_2 %>% 
  group_by(Age) %>% 
  summarise(RSL = mean(RSL))
#---Removing the offset of 7000mm---
SL_df_site_1_2$RSL <- SL_df_site_1_2$RSL - 7000
#--Plotting 2 sites----
test_plot <- ggplot()+
  geom_point(data = SL_df_site_1_2, aes(x = Age, y = RSL))+
  facet_wrap(~id)
test_plot

###------------Loop to open all RSL & Age data files------------
read_plus <- function(flnm) {
  fread(flnm, sep= ";") %>% # fread quicker way to read in & allows for ; to be used
    mutate(filename = flnm) # allows you to include the file name as id
}

temp_SL<-
  list.files(path = "rlr_monthly/data",
             pattern = "*.rlrdata", 
             full.names = T) %>% 
  map_df(~read_plus(.)) %>%  as.tibble()
# Warnings there are some files without data
colnames(temp_SL) = c("Age","RSL","flag_attention_1","flag_attention_2","id")
SL_df <- temp_SL %>% 
  mutate(id = str_extract(id,"[0-9]+")) %>% # pulling out the file number from string
  filter(!RSL== -99999) %>%  # Cases where bad data was collected
  mutate(RSL = RSL- 7000) %>% # Removing the offset. RSL in mm 
  group_by(Age,id) %>% # Getting the mean RSL value for each year
  mutate(RSL = mean(RSL))

#--Joining SL data with location names--
annual_SL_tide_df <-merge(SL_df,file_list,by = "id",all = TRUE)
#-- Removing sites which have a station flag raised as they are poor sites---
annual_SL_tide_df <- annual_SL_tide_df %>%
  filter(!stationflag == "Y") %>% 
  drop_na()# %>% 
  #Weird outliers
  #filter(RSL > -4000) %>%  # Site in Cyprus -4244mm
  #filter(RSL < 2800) # Site in Russia 2830mm

write.csv(annual_SL_tide_df,"annual_monthly_SL_tide_df.csv")
#--Plotting Tidal gauge data---
full_data_plot <- ggplot()+
  geom_line(data = annual_SL_tide_df, aes(x = Age, y = RSL,colour = name))+
  theme(legend.position="none")
  #facet_wrap(~id)
full_data_plot

#--Global Mean Sea Level---
gmsl_tidal_gauge <- annual_SL_tide_df %>% 
  mutate(Age = round(Age,digits=0)) %>% 
  group_by(Age) %>% 
  summarise(RSL = mean(RSL))
gmsl_plot <- 
  ggplot()+
  geom_line(data = gmsl_tidal_gauge, aes(x = Age, y = RSL))+
  theme(legend.position="none")+
  ggtitle("Global Mean Sea Level from PSMSL Tide Gauge Data")+
  xlab("Age (CE)")+
  ylab("RSL (mm)")+
  theme_bw()
#facet_wrap(~id)
gmsl_plot
