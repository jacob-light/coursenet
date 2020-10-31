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
# Load course description data
############################
  # data_in <- readRDS('course_input.RDS')
  # 
  # # Restrict to most recent year of data by institution-department
  # data_in <- data_in %>%
  #   group_by(institution, department) %>%
  #   mutate(most_recent = max(start)) %>%
  #   filter(start == most_recent) %>%
  #   ungroup()
  # 
  # write_csv(data_in %>%
  #             select(title, desc, department, course_no, institution, blom_group),
  #           'course_input.csv')
  
############################
# Tokenize data
############################
  data_in <- read_csv('input/course_input.csv')
  
  # Collapse to department level
  data_collapse <- data_in %>%
    group_by(institution, department, blom_group) %>%
    mutate(desc2 = paste0(desc, collapse = ' ')) %>%
    select(-c(desc, title, course_no)) %>%
    unique() %>%
    ungroup()
  # write_csv(data_collapse,
  #           'input/course_input.csv')

############################
# CREATE CORPUS
############################
  # Tokenize all descriptions
  desc_words <- data_collapse %>%
    unnest_tokens(output = word, input = desc2) %>%
    count(department, institution, blom_group, word, sort = TRUE) %>%
    # Remove stop words
    filter(word %in% stopwords('en') == FALSE) %>%
    # Remove numeric
    filter(!str_detect(word, '[0-9]'))
  data_collapse <- data_collapse %>%
    filter(desc2 != '')

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
  data_nested <- data_collapse_unnest %>%
    group_by(department, institution, blom_group) %>%
    summarize(desc = paste0(word, collapse = ' ')) %>%
    ungroup()
  write_csv(data_nested, 'input/courses_nested.csv')
    
  # # To avoid grouping on institution rather than department, remove all words
  # # associated with only one major
  # data_coll_inst <- data_collapse_unnest %>%
  #   select(word, institution) %>%
  #   group_by(institution) %>%
  #   filter(!duplicated(word)) %>%
  #   ungroup() %>%
  #   group_by(word) %>%
  #   summarize(count = n()) %>%
  #   filter(count == 1) %>%
  #   select(-count)
  # data_collapse_unnest <- data_collapse_unnest %>%
  #   anti_join(data_coll_inst)
  # rm(data_coll_inst)
  # 
  # # TF-IDF
  # N <- 1000
  # tf_idf_cat <- data_collapse_unnest %>%
  #   group_by(blom_group, word) %>%
  #   summarize(count = n()) %>%
  #   ungroup() %>%
  #   bind_tf_idf(word, blom_group, count) %>%
  #   # Choose 6000 most common words
  #   arrange(-tf_idf) %>%
  #   slice(1:N) %>%
  #   select(word)  
  # 
  # # Build X-matrix
  # x_matrix2 <- data_collapse_unnest %>%
  #   filter(word %in% tf_idf_cat$word) %>%
  #   count(institution, department, blom_group, word) %>%
  #   mutate(unique_id = paste0(institution, department, blom_group, sep = '__')) %>%
  #   cast_dtm(document = unique_id, term = word, value = n) %>%
  #   as.matrix() %>%
  #   t()
  # 
  # # Some observations are dropping
  # 
  # # Build Y-matrix
  # y_matrix <- data_collapse %>%
  #   filter(word %in% tf_idf_cat$word) %>%
  #   select(blom_group) %>%
  #   mutate(blom_group = as.factor(blom_group))
  # y_matrix <- y_matrix %>%
  #   as.data.table() %>%
  #   one_hot()
  # colnames(y_matrix) <- str_replace(colnames(y_matrix), 'blom_group_', '')
  # y_matrix <- y_matrix %>%
  #   as.matrix() %>%
  #   t()
  # 
  # # Save output
  # write_csv(x_matrix2 , 'intermediate/x_matrix.csv')
  # write_csv(y_matrix, 'intermediate/y_matrix.csv')
  # 
  # 