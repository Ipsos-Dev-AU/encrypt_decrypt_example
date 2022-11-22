library(RODBC)
library(shiny)
library(shinydashboard)
library(tidyverse)
library(shinyWidgets)
library(shinyjs)
library(lubridate)
library(shinyTime)
library(data.table)
library(shinyalert)
library(shiny)
library(shinythemes)
library(RODBC)
library(dplyr)
library(ggplot2)
library(DT)
library(data.table)
library(dplyr)
library(shinyjs)
library(shinyWidgets)
library(shinyTime)
library(shinyBS)
library(shinyalert)
library(shinydashboard)
library(plotly)
library(shinyToastify)
library(xlsx)
library(writexl)
library(encryptr)
source("/home/zachary.loh@ipsosgroup.ipsos.com/iMOB_PCP/UAT/.Rprofile")
#setwd("/home/zachary.loh@ipsosgroup.ipsos.com/iMOB_PCP/UAT")
#source(".Rprofile")
#source("/home/zachary.loh@ipsosgroup.ipsos.com/iMOB_PCP/Creds.R")
database <- "iMob"
db_schema <- paste0("[",database, "].[dbo].[")
dbhandelstring <- paste0("driver=",Sys.getenv("driver"),
                         ";server=",Sys.getenv("server"),
                         ";database=",Sys.getenv("database"),
                         ";port=", Sys.getenv("port"),
                         ";trusted_connection=",Sys.getenv("trusted_connection"),
                         ";uid=", Sys.getenv("uid"),
                         ";pwd=", Sys.getenv("pwd")
)
print(dbhandelstring)
dbhandle <- odbcDriverConnect(
  dbhandelstring
)