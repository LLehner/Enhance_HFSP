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


df <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/mmseqs2/outputs/run1.tsv")
ec_numbers <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/3_after_ec_filtering/Swiss-Prot_2002_redundancy_reduced_50.tsv")


df_filtered <- df %>%
  filter(query != target) %>%
  group_by(query) %>%
  filter(bits == max(bits)) %>%
  ungroup() %>%
  mutate(ug_alnlen = sapply(cigar, calculate_ungapped_length))

ec_numbers <- ec_numbers %>%
  dplyr::select(id, ec3)

data <- data.table(
  inner_join(
    inner_join(df_filtered, ec_numbers, by=c("query" = "id")) %>%
      dplyr::rename(ec3_query = ec3),
    ec_numbers,
    by = c("target" = "id")
  ) %>%
    dplyr::rename(ec3_target = ec3) %>%
    mutate(ec3_same = ec3_query == ec3_target)
) 

data[ec3_same == "TRUE", ec3_same_new := "same 3rd level EC"]
data[ec3_same == "FALSE", ec3_same_new := "different 3rd level EC"]
data$ec3_same_new <- factor(data$ec3_same_new)

L.values <- seq(11, max(data$ug_alnlen), 1)
#hssp.1991 <- data.table(L = L.values, HSSP.1991 = sapply(L.values, get.hssp.1991))
hssp.2018 <- data.table(L = L.values, HSSP.2018 = sapply(L.values, get.hssp.2018))
hfsp.2018 <- data.table(L = L.values, HFSP.2018 = sapply(L.values, get.hfsp.2018))


plot <- ggplot(data, aes(x = ug_alnlen, y = pident, color = ec3_same_new)) +
  geom_point() +
  geom_line(data = hfsp.2018, aes(x = L, y = HFSP.2018, color="HFSP-2018"), linewidth = 1.5) +
  geom_line(data = hssp.2018, aes(x = L, y = HSSP.2018, color = "HSSP-2002"), linewidth = 1.5) +
  scale_color_manual(name = element_blank(),
                     values = c("same 3rd level EC" = "darkgreen",
                                "different 3rd level EC" = "orange",
                                "HSSP-2002" = "blue",
                                "HFSP-2018" = "#FF00FF"),
                     limits = c("HSSP-2002",
                                "HFSP-2018",
                                "same 3rd level EC",
                                "different 3rd level EC")) +
  labs(x = "Ungapped alignment length", y = "Sequence identity (%)", color = "same EC") +
  ylim(0, 100) +
  xlim(0, 1550) +
  ggtitle("MMSeqs2") +
  theme_cowplot() +
  theme(legend.position = "bottom", 
        legend.justification = "center",
        legend.spacing.x = unit(3, "cm")) +
  guides(color = guide_legend(nrow = 4, byrow = T))

# p <- ggMarginal(
#   ggplot() +
#     geom_point(data = data %>% filter(ec_3_same), aes(x = ug_alnlen, y = pident), color = "darkgreen", shape="circle") +
#     geom_point(data = data %>% filter(!ec_3_same), aes(x = ug_alnlen, y = pident), color = "orange", shape="triangle") +
#     geom_line(data = hfsp.2018, aes(x = L, y = HFSP.2018), linewidth = 1.5, color="red") +
#     geom_line(data = hssp.2018, aes(x = L, y = HSSP.2018), linewidth = 1.5, color = "blue") +
#     labs(x = "Ungapped alignment length", y = "Percentage of identical residues") +
#     ggtitle("Coverage 0.5") +
#     ylim(0, 100) +
#     theme_cowplot(),
#   groupColour = T, groupFill = T)

p <- ggMarginal(plot, groupColour = T, groupFill = T)

#ggsave("~/foldseek.png", p, width = 3000, height = 1000, units = "px")
