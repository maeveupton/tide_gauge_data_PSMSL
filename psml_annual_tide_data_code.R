#-----Updated PSMSL Tide Data Code-----
# Reference: https://gist.github.com/flare9x/a13482087e322b8ba6c208194c85a182
#--Annual Data---
rm(list = ls())
# Set Directory
setwd("/Users/mupton/Desktop/Github/tide_gauge_data_PSMSL")
library(tidyverse)
library(data.table)

###------Individual File Reading Test-------
# Read the gauge file list (location, names)
file_list <- read.csv("rlr_annual/filelist.txt",stringsAsFactors = FALSE, header=F,sep=";")
colnames(file_list)<- c("id","Latitude","Longitude","name","coastline","stationcode","stationflag")
# Removing white space in the name of each site
file_list$name <- gsub("[[:space:]]", "",file_list$name)
file_list$stationflag <- gsub("[[:space:]]", "",file_list$stationflag)

# Read 1st data set - oldest station with 1807 start date (sets the initial date)
site_1 <- read.csv("rlr_annual/data/1.rlrdata",stringsAsFactors = FALSE, header=F,sep=";")
site_1$V2[site_1$V2 == -99999] <- NA
site_1$id <- "1"
#--What is flag_attention_2?---
colnames(site_1) = c("Age","RSL","flag_attention_1","flag_attention_2","id")
# Combining file list (location,names) with the SL vs Age data for site 1
full_site_1_df <- merge(site_1,file_list[1,])

# Read 2nd data set
site_2 <- read.csv("rlr_annual/data/10.rlrdata",stringsAsFactors = FALSE, header=F,sep=";")
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
#---Removing the offset of 7000mm---
SL_df_site_1_2$RSL <- SL_df_site_1_2$RSL - 7000

# #--Plotting 2 sites----
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
  list.files(path = "rlr_annual/data",
             pattern = "*.rlrdata", 
             full.names = T) %>% 
  map_df(~read_plus(.)) %>%  as.tibble()
# Warnings: there are some files without data
colnames(temp_SL) = c("Age","RSL","flag_attention_1","flag_attention_2","id")

SL_df <- temp_SL %>% 
  #mutate(id = as.factor(str_extract(id,"[0-9]+"))) %>% # pulling out the file number from string
  mutate(id = str_extract(id,"[0-9]+")) %>% # pulling out the file number from string
  filter(!RSL== -99999) %>%  # Cases where bad data was collected
  # mutate(RSL = RSL - 7000) # Offset
  group_by(id) %>% #2000-2018 used as the tidal epoch
  mutate(Age_epoch_id = ifelse(between(Age,2000,2018),TRUE,FALSE))

#--- Removing offset based on the location---
# Offset value is the mean of RSL over the tidal epoch
# Setting 2000-2018 as the tidal epoch
Age_epoch_ref <-  SL_df %>% 
  dplyr::select(RSL,Age_epoch_id) %>% 
  filter(Age_epoch_id == TRUE) %>% 
  summarise(RSL_offset  = unique(mean(RSL)))

SL_df <- merge(SL_df,Age_epoch_ref,by = "id",all=TRUE)
# Cases where no data between 2000-2018 set the offset to 7000
SL_df$RSL_offset[is.na(SL_df$RSL_offset)] <- 7000

# Updating the RSL to the shifted RSL value 
SL_df$RSL <- SL_df$RSL - SL_df$RSL_offset
  
#--Joining SL data with location names--
annual_SL_tide_df <-merge(SL_df,file_list,by = "id",all = TRUE)
#-- Removing sites which have a station flag raised as they are poor sites---
annual_SL_tide_df <- annual_SL_tide_df %>%
  filter(!stationflag == "Y") %>% 
  drop_na() 

write.csv(annual_SL_tide_df,"annual_SL_tide_df.csv")

#--Plotting Tidal gauge data---
full_data_plot <- ggplot()+
  geom_line(data = annual_SL_tide_df, aes(x = Age, y = RSL,colour = name))+
  theme(legend.position="none")#+
  #facet_wrap(~id)
full_data_plot

#--Global Mean Sea Level---
gmsl_tidal_gauge <- annual_SL_tide_df %>% 
  group_by(Age) %>% 
  summarise(RSL = mean(RSL))
gmsl_plot <- 
  ggplot()+
  geom_line(data = gmsl_tidal_gauge, aes(x = Age, y = RSL))+
  theme(legend.position="none")
#facet_wrap(~id)
gmsl_plot
