library(M3C)
library(plotly)
library(ggbiplot)
library(devtools)
## install_github("vqv/ggbiplot")
## install.packages("BiocManager")
## BiocManager::install("M3C") 

options(scipen = 999)
tuesday <- read.table("dados/Tuesday-WorkingHours.pcap_ISCX.csv", sep = ",", head = T)
tuesday <- tuesday[tuesday$Label != "BENIGN",]

wednesday <- read.table("dados/Wednesday-workingHours.pcap_ISCX.csv", sep = ",", head = T)
wednesday_not_hulk <- wednesday[!(wednesday$Label %in% c("BENIGN", "DoS Hulk")),]
wednesday_hulk <- wednesday[(wednesday$Label %in% c("DoS Hulk")),]
wednesday_hulk <- wednesday_hulk[sample(1:nrow(wednesday_hulk), round(nrow(wednesday_hulk)*0.05)),]
wednesday_final <- rbind(wednesday_not_hulk, wednesday_hulk)
table(wednesday_final$Label)

thu_mor <- read.table("dados/Thursday-WorkingHours-Morning-WebAttacks.pcap_ISCX.csv", sep = ",", head = T)
thu_mor <- thu_mor[thu_mor$Label != "BENIGN",]
table(thu_mor$Label)

thu_aft <- read.table("dados/Thursday-WorkingHours-Afternoon-Infilteration.pcap_ISCX.csv", sep = ",", head = T)
thu_aft <- thu_aft[thu_aft$Label != "BENIGN",]

friday_ddos <- read.table("dados/Friday-WorkingHours-Afternoon-DDos.pcap_ISCX.csv", sep = ",", head = T)
friday_ddos <- friday_ddos[friday_ddos$Label != "BENIGN",]
friday_ddos <- friday_ddos[sample(1:nrow(friday_ddos), round(nrow(friday_ddos)*0.1)),]
table(friday_ddos$Label)

friday_scan <- read.table("dados/Friday-WorkingHours-Afternoon-PortScan.pcap_ISCX.csv", sep = ",", head = T)
friday_scan <- friday_scan[friday_scan$Label != "BENIGN",]
friday_scan <- friday_scan[sample(1:nrow(friday_scan), round(nrow(friday_scan)*0.1)),]

table(friday_scan$Label)

friday <- read.table("dados/Friday-WorkingHours-Morning.pcap_ISCX.csv", sep = ",", head = T)
friday <- friday[friday$Label != "BENIGN",]

atack_full <- rbind(tuesday, wednesday_final, thu_aft, thu_mor, friday, friday_ddos, friday_scan)
table(atack_full$Label)

attacks_types <- c("FTP-Patator", "SSH-Patator", "DoS slowloris", "DoS Slowhttptest", "DoS GoldenEye", "DoS Hulk", "Web Attack � Brute Force", "Web Attack � XSS", "DDoS")
atack_full <- atack_full[atack_full$Label %in% attacks_types,]
table(atack_full$Label)

atack_full_scaled <- as.data.frame(scale(atack_full[,c(-1,-2,-79)]))

## Tsne 

id <- which(!is.nan(unlist(atack_full_scaled[1,])))
atack_full_scaled <- atack_full_scaled[complete.cases(atack_full_scaled[,id]), id]
atack_full_scaled$label <- atack_full$Label
atack_full_scaled <- atack_full_scaled[!duplicated(atack_full_scaled[, -63]), ]

atack_full_scaled$label <- as.factor(atack_full_scaled$label)
levels(atack_full_scaled$label) <- c("DDoS Loit","DoS GoldenEye","DoS Hulk","DoS Slowhttptest","DoS slowloris",
                                     "FTP-Patator","SSH-Patator","Web Attack-Brute Force","Web Attack-XSS")

M3C::tsne(t(atack_full_scaled[, -63]), labels=atack_full_scaled$label, perplex = 100, dotsize = 3)


## PCA 


results <- prcomp(atack_full_scaled[, -63])
variance <- cumsum(results$sdev^2 / sum(results$sdev^2))
head(results$x)
PCA <- data.frame(results$x)
PCA$label <- atack_full_scaled$label

fig <- plot_ly(data = PCA, x = ~PC1, y = ~PC2, color = ~label)

fig

ggbiplot(results ,ellipse=TRUE)

plot(variance[0:15], xlab = "PC #", ylab = "Amount of explained variance", main = "Cumulative variance plot")