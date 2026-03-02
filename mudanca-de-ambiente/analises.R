library(xgboost)
library(data.table)
library(pROC)
library(caret)
library(randomForest)
library(M3C)
library(plotly)
library(ggbiplot)
library(devtools)
library(reshape2)
library(ROCR)
library(lubridate)
library(Rtsne)
set.seed(456)

#### dados coletados ######

same_attacks_attack_target_dt1 <- read.csv("~/other_projects/same_attacks/dataset/same_attacks_attack_target_dt1.csv", sep = ";")
same_attacks_attack_target_dt2 <- read.csv("~/other_projects/same_attacks/dataset/same_attacks_attack_target_dt2.csv", sep = ";")
same_attacks_normal_dt1 <- read.csv("~/other_projects/same_attacks/dataset/same_attacks_normal_dt1.csv")
same_attacks_normal_dt2 <- read.csv("~/other_projects/same_attacks/dataset/same_attacks_normal_dt2.csv")


same_attacks_normal_dt1$data <- as_datetime(same_attacks_normal_dt1$bidirectional_first_seen_ms / 1000, tz = "UTC")
same_attacks_normal_dt1$data <- with_tz(same_attacks_normal_dt1$data, tzone = "America/Sao_Paulo")
same_attacks_normal_dt1$label <- "benign"

same_attacks_normal_dt2$data <- as_datetime(same_attacks_normal_dt2$bidirectional_first_seen_ms / 1000, tz = "UTC")
same_attacks_normal_dt2$data <- with_tz(same_attacks_normal_dt2$data, tzone = "America/Sao_Paulo")
same_attacks_normal_dt2$label <- "benign"


##### dados CIC2017 ######## 


CIC2017 <- read.csv("~/data/cic2017-csv/CIC2017-nfstream-target.csv", sep=";")

####### Modelo base ####### 

df.train <- rbind(same_attacks_normal_dt1, same_attacks_attack_target_dt1)
df.test <- rbind(same_attacks_normal_dt2, same_attacks_attack_target_dt2)

## precisa ordenar pela data e selecionar um ataque e rodar o modelo
df.train <- data.frame(data.table(df.train)[order(data)])
df.test <- data.frame(data.table(df.test)[order(data)])


vars <- c("bidirectional_duration_ms",
          "bidirectional_packets",
          "bidirectional_bytes",
          "src2dst_duration_ms",
          "src2dst_packets",
          "src2dst_bytes",
          "dst2src_duration_ms",
          "dst2src_packets",
          "dst2src_bytes",
          "bidirectional_min_ps",
          "bidirectional_mean_ps",
          "bidirectional_stddev_ps",
          "bidirectional_max_ps",
          "src2dst_min_ps",
          "src2dst_mean_ps",
          "src2dst_stddev_ps",
          "src2dst_max_ps",
          "dst2src_min_ps",
          "dst2src_mean_ps",
          "dst2src_stddev_ps",
          "dst2src_max_ps",
          "bidirectional_min_piat_ms",
          "bidirectional_mean_piat_ms",
          "bidirectional_stddev_piat_ms",
          "bidirectional_max_piat_ms",
          "src2dst_min_piat_ms",
          "src2dst_mean_piat_ms",
          "src2dst_stddev_piat_ms",
          "src2dst_max_piat_ms",
          "dst2src_min_piat_ms",
          "dst2src_mean_piat_ms",
          "dst2src_stddev_piat_ms",
          "dst2src_max_piat_ms",
          "bidirectional_syn_packets",
          "bidirectional_cwr_packets",
          "bidirectional_ece_packets",
          "bidirectional_urg_packets",
          "bidirectional_ack_packets",
          "bidirectional_psh_packets",
          "bidirectional_rst_packets",
          "bidirectional_fin_packets",
          "src2dst_syn_packets",
          "src2dst_cwr_packets",
          "src2dst_ece_packets",
          "src2dst_urg_packets",
          "src2dst_ack_packets",
          "src2dst_psh_packets",
          "src2dst_rst_packets",
          "src2dst_fin_packets",
          "dst2src_syn_packets",
          "dst2src_cwr_packets",
          "dst2src_ece_packets",
          "dst2src_urg_packets",
          "dst2src_ack_packets",
          "dst2src_psh_packets",
          "dst2src_rst_packets",
          "dst2src_fin_packets")
attack <- "DoS-Hulk"
target <- "label"

analises <- function(attack){
  Xtrain <- df.train[df.train$label %in% c("benign", attack) ,vars]
  Ytrain <- df.train[df.train$label %in% c("benign", attack) ,target]
  Ytrain <- ifelse(Ytrain == "benign", 0, 1)
  
  Xtest <- df.test[df.test$label %in% c("benign", attack) ,vars]
  Ytest <- df.test[df.test$label %in% c("benign", attack) ,target]
  Ytest <- ifelse(Ytest == "benign", 0, 1)
  
  #### Xgboost ######
  
  # Parameters
  # params <- list(
  #   base_score = 0.5,
  #   booster = "gbtree",
  #   colsample_bylevel = 1,
  #   colsample_bytree = 0.81,
  #   gamma = 1.0,
  #   learning_rate = 0.03,
  #   max_delta_step = 8,
  #   max_depth = 4,
  #   min_child_weight = 30,
  #   random_state = 0,
  #   reg_alpha = 0,
  #   reg_lambda = 1,
  #   scale_pos_weight = 1,
  #   subsample = 0.9,
  #   eval_metric = "auc"
  # )
  # 
  # Assuming X_train, y_train, X_test, and y_test are already defined as matrices or data frames
  
  # Convert data to DMatrix format
  dtrain <- xgb.DMatrix(data = as.matrix(Xtrain), label = Ytrain)
  dtest <- xgb.DMatrix(data = as.matrix(Xtest), label = Ytest)
  
  
  # Create the XGBoost classifier
  # clf <- xgb.train(data = dtrain,
  #                  params = params,
  #                  nrounds = 1166,
  #                  objective = "binary:logistic",
  #                  verbose = 0) # Set verbose to 1 if you want to see output
  
  # Predict probabilities
  # prob_train <- predict(clf, dtrain)
  # prob_test <- predict(clf, dtest)
  # print("XGBOOST")
  # # Calculate AUC
  # roc_curve <- roc(Ytest, prob_test, smooth = T,positive="1")
  # auc_value <- auc(roc_curve)
  # print(paste("AUC:", auc_value))
  
  # Calculate F1 Score
  # pred_classes <- ifelse(prob_test > 0.5, 1, 0)
  # confusion_matrix <- confusionMatrix(factor(pred_classes), factor(Ytest), positive = "1")
  # f1_score <- confusion_matrix$byClass['F1']
  # print(paste("F1 Score:", f1_score))
  # print(confusion_matrix)
  
  # Plot ROC Curve
  # plot(roc_curve, main = "ROC Curve")
  # abline(a=0, b=1, col="red", lty=2)  # Diagonal line for reference
  
  
  ##### Random Forest ##### 
  print("RF")
  train_data <- df.train[df.train$label %in% c("benign", attack) ,c(vars, target)]
  test_data <- df.test[df.test$label %in% c("benign", attack) ,c(vars, target)]
  
  train_data$label <- as.factor(ifelse(train_data$label=="benign", 0, 1))
  test_data$label <- as.factor(ifelse(test_data$label=="benign", 0, 1))
  
  rf_model <- randomForest(label ~ ., data = train_data, ntree = 100)
  
  # Make predictions on the test set
  pred_probs <- predict(rf_model, newdata = test_data, type = "prob")[, 2]
  
  roc_curve <- roc(Ytest, pred_probs)
  auc_value <- auc(roc_curve)
  print(paste("AUC:", auc_value))
  ## AUC 0.99
  
  # Calculate F1 Score
  pred_classes <- predict(rf_model, newdata = test_data, type = "response")
  confusion_matrix <- confusionMatrix(factor(pred_classes), factor(Ytest), positive = "1")
  confusion_matrix$table
  f1_score <- confusion_matrix$byClass['F1']
  print(paste("F1 Score:", f1_score))
  print(confusion_matrix)
  ## F1 0.99
  
  # Plot ROC Curve
  plot(roc_curve, main = "ROC Curve")
  abline(a=0, b=1, col="red", lty=2)  # Diagonal line for reference
  
  
  ########## transfer learning ######## 
  
  print("Transfer Learning")
  transfer_data <- CIC2017[CIC2017$label %in% c("benign", attack) ,c(vars, target)]
  transfer_data$label <- as.factor(ifelse(transfer_data$label=="benign", 0, 1))
  Ytransfer <- transfer_data$label
  
  # Make predictions on the test set
  pred_probs <- predict(rf_model, newdata = transfer_data, type = "prob")[, 2]
  
  roc_curve <- roc(Ytransfer, pred_probs)
  auc_value <- auc(roc_curve)
  print(paste("AUC:", auc_value))
  ## "AUC: 0.852723918841015"
  
  # Calculate F1 Score
  pred_classes <- predict(rf_model, newdata = transfer_data, type = "response")
  confusion_matrix <- confusionMatrix(factor(pred_classes), Ytransfer, positive = "1")
    f1_score <- confusion_matrix$byClass['F1']
  print(paste("F1 Score:", f1_score))
  ## F1 Score: 0.997780045257989
  print(confusion_matrix)
  
  # Plot ROC Curve
  plot(roc_curve, main = "ROC Curve")
  abline(a=0, b=1, col="red", lty=2)  # Diagonal line for reference
  
  
  ####### propensity ####### 
  print("Propensity")
  p.same <- df.train[df.train$label == attack ,c(vars)]
  p.same$label <- 0
  p.cic <- CIC2017[CIC2017$label == attack ,c(vars)] 
  p.cic$label <- 1
  p.total <- rbind(p.same,p.cic)   
  id <- sample(1:nrow(p.total), round(0.7*nrow(p.total)))
  p.train <- p.total[id,]
  p.test <- p.total[-id,]
  
  p.train$label <- as.factor(p.train$label)
  p.test$label <- as.factor(p.test$label)
  y.ptest <- p.test$label
  
  rf_model <- randomForest(label ~ ., data = p.train, ntree = 100)
  
  # Make predictions on the test set
  pred_probs <- predict(rf_model, newdata = p.test, type = "prob")[, 2]
  
  roc_curve <- roc(y.ptest, pred_probs)
  auc_value <- auc(roc_curve)
  print(paste("AUC:", auc_value))
  ## AUC 0.99
  
  # Calculate F1 Score
  pred_classes <- predict(rf_model, newdata = p.test, type = "response")
  confusion_matrix <- confusionMatrix(factor(pred_classes), y.ptest, positive = "1")
  f1_score <- confusion_matrix$byClass['F1']
  print(paste("F1 Score:", f1_score))
  print(confusion_matrix)
  ## F1 0.99
  
  # Plot ROC Curve
  plot(roc_curve, main = "ROC Curve")
  abline(a=0, b=1, col="red", lty=2)  # Diagonal line for reference
  
  
  ##### tsne #### 
  
  label <- as.factor(p.total$label)
  p.total.scale <- as.data.frame(scale(p.total[,-58]))
  id <- which(!is.nan(unlist(p.total.scale[1,])))
  p.total.scale <- p.total.scale[complete.cases(p.total.scale[,id]), id]
  p.total.scale$label <- label 
  # p.total.scale <- p.total.scale[!duplicated(p.total.scale[, -ncol(p.total.scale)]), ]
  p.total.scale$label <- as.numeric(as.character(p.total.scale$label))
  levels(p.total.scale$label) <- c("SIM","CIC")
  
  ts <- Rtsne(p.total.scale[,-ncol(p.total.scale)], labels=p.total.scale$label, perplex = 50, check_duplicates = F)
  scores <- as.data.frame(ts$Y)
  colnames(scores) <- c("X1", "X2")
  
  scores$label <- label
  
  fig <- plot_ly(data = scores, x = ~X1, y = ~X2, color = ~label)
  print(fig)

  ## PCA 
  
  
  results <- prcomp(p.total.scale[,-ncol(p.total.scale)])
  variance <- cumsum(results$sdev^2 / sum(results$sdev^2))
  head(results$x)
  PCA <- data.frame(results$x)
  PCA$label <- p.total.scale$label
  
  fig <- plot_ly(data = PCA, x = ~PC1, y = ~PC2, color = ~label)
  
  print(fig)
  
  
  ### distribuição das principais variaveis RF ###
  
  varsImp <- data.frame(vars = row.names(rf_model$importance),rf_model$importance)
  varsImp<- data.frame(data.table(varsImp)[order(-MeanDecreaseGini)])
  
  varsRF <- varsImp[1:10,1]
  
  p.total.melt <- melt(p.total.scale[,c(varsRF,target)], id = target)
  
  p.total.melt$label <- as.factor(as.character(p.total.melt$label))
  levels(p.total.melt$label) = c("SIM", "CIC")
  
  
  fig <- plot_ly(p.total.melt, x = ~variable, y = ~value, color = ~label, type = "box")
  fig <- fig %>% layout(boxmode = "group")
  
  print(fig)
}



analises("DoS-Hulk")
analises("DoS-Slowhttptest")
analises("DoS-slowloris")
analises("FTP-Patator")
analises("SSH-Patator")
analises("Port-Scan")



