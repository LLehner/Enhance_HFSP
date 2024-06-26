library(ggplot2)
library(ggExtra)
library(data.table)
library(readxl)
library(dplyr)
library(cowplot)

calculate_ungapped_length <- function(cigar_string) {
  lengths <- as.numeric(unlist(strsplit(gsub("[A-Z]", " ", cigar_string), " ")))
  operations <- unlist(strsplit(gsub("[0-9]", "", cigar_string), ""))
  
  ungapped_length <- sum(lengths[operations == "M"])
  
  return(ungapped_length)
}

get.hssp.1991 <- function(L) {
  if (L < 80) {
    return(290.15 * L ^ -0.562)
  } else {
    return(25)
  }
}

get.hssp.2018 <- function(L) {
  if (L <= 11) {
    return(100)
  } else if (11 < L & L <= 450) {
    return(480 * L ^ (-0.32 * (1 + exp(1) ^ (-L / 1000))))
  } else {
    return(19.5)
  }
}

get.hfsp.2018 <- function(L) {
  if (L <= 11) {
    return(100)
  } else if (11 < L & L <= 450) {
    return(770 * L ^ (-0.33 * (1 + exp(1) ^ (-L / 1000))))
  } else {
    return(28.4)
  }
}


df <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/foldseek/outputs/run1.tsv")
ec_numbers <- data.table(read_excel("/nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/hfsp_supplement/Mahlich.335.sup.data.1.xlsx", sheet = 2))

df_filtered <- df %>%
  filter(query != target) %>%
  group_by(query) %>%
  filter(bits == max(bits)) %>%
  ungroup() %>%
  mutate(ug_alnlen = sapply(cigar, calculate_ungapped_length))

ec_numbers <- ec_numbers %>%
  mutate(ec_3 = sapply(strsplit(as.character(ec_number), "\\."), function(x) paste(x[1:3], collapse = "."))) %>%
  dplyr::select(id, ec_3)

data <- data.table(
  inner_join(
    inner_join(df_filtered, ec_numbers, by=c("query" = "id")) %>%
      dplyr::rename(ec_3_query = ec_3),
    ec_numbers,
    by = c("target" = "id")
  ) %>%
    dplyr::rename(ec_3_target = ec_3) %>%
    mutate(ec_3_same = ec_3_query == ec_3_target)
) 

L.values <- seq(0, max(data$ug_alnlen), 1)
hssp.1991 <- data.table(L = L.values, HSSP.1991 = sapply(L.values, get.hssp.1991))
hssp.2018 <- data.table(L = L.values, HSSP.2018 = sapply(L.values, get.hssp.2018))
hfsp.2018 <- data.table(L = L.values, HFSP.2018 = sapply(L.values, get.hfsp.2018))


p <- ggMarginal(
  ggplot() +
    geom_point(data = data %>% filter(ec_3_same), aes(x = ug_alnlen, y = pident), color = "darkgreen", shape="circle") +
    geom_point(data = data %>% filter(!ec_3_same), aes(x = ug_alnlen, y = pident), color = "orange", shape="triangle") +
    geom_line(data = hfsp.2018, aes(x = L, y = HFSP.2018), linewidth = 1.5, color="red") +
    geom_line(data = hssp.2018, aes(x = L, y = HSSP.2018), linewidth = 1.5, color = "blue") +
    labs(x = "Ungapped alignment length", y = "Percentage of identical residues") +
    ggtitle("Coverage 0.5") +
    ylim(0, 100) +
    theme_cowplot(),
  type = "histogram")


ggsave("~/coverage.png", p, width = 1420, height = 1080, units = "px", dpi = 150)
