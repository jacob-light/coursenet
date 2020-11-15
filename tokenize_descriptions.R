################################################
# Name: Jacob Light
# Date: 2020.10.26
# Course: CS 230
# Project: courseNet
# Description: Transform clean course descriptions into
# bag of words, vectorize courses (departments)
################################################
  rm(list = ls())
  
  # setwd(path)
  options(scipen=999)
  options(dplyr.summarise.inform=F)
  options(max.print = 25)
  
  library(tidyr)
  library(dplyr)
  library(stringr)
  library(readr)
  library(ggplot2)
  library(rmarkdown)
  library(kableExtra)
  library(utils)
  library(readxl)
  library(xml2)
  library(knitr)
  library(tokenizers)
  library(stopwords)
  library(tidytext)
  library(mltools)
  library(data.table)
  library(SnowballC)

############################
# FUNCTIONS
############################  
# Takes data frame as input, returns 

############################
# Tokenize data
############################
  # Load processed course description data
  data_in <- readRDS('input/course_input.RDS')
  
  # Load institution characteristics
  inst_characteristics <- read_xlsx('input/2020.03.11 Catalog Websites.xlsx', sheet = 'inst_summary')
  
  # Collapse to institution-department level
  data_collapse <- data_in %>%
    group_by(institution, department, blom_group) %>%
    mutate(desc2 = paste0(desc, collapse = ' ')) %>%
    select(-c(desc, title, course_no)) %>%
    unique() %>%
    ungroup()

############################
# Document-term matrix
############################
  # Transform descriptions to word stems
  data_collapse_unnest <- data_collapse %>%
    unnest_tokens(output = word, input = desc2) %>%
    # Remove stop words
    anti_join(stop_words) %>%
    # Remove punctuation
    .[-grep("\\b\\d+\\b", .$word),] %>%
    mutate_at('word', funs(wordStem((.), language = 'en')))
  
  # Collapse entries down to institution-department level
  data_nested <- data_collapse_unnest %>%
    group_by(department, institution, blom_group) %>%
    summarize(desc = paste0(word, collapse = ' ')) %>%
    ungroup() %>%
    # Data cleaning - remove errant/unclassified departments, merge in 
    # institution characteristics
    filter(!is.na(blom_group), blom_group != '0') %>%
    inner_join(inst_characteristics %>% select(institution, size_cat, type)) %>%
    select(institution, size_cat, type, department, blom_group, desc)  

  write_csv(data_nested, 'input/courses_nested.csv')
  
############################
# Collapse to department level
############################  
  # To build corpus/for tf-idf, want to assess (dis)similarity across labeled groups,
  # not repeated observations
  data_nested_cat <- data_nested %>%
    group_by(blom_group) %>%
    summarize(desc = paste0(desc, collapse = ' ')) %>%
    ungroup()
  
  write_csv(data_nested_cat, 'input/courses_nested_grouped.csv')
  

  
  
  
