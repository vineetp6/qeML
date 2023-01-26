


#########################  qeLogitKNN()  #################################

# fit logistic model, then fit KNN to residuals

# arguments:  as in Quick.R, plus

#     k: number of nearest neighbors
#     scaleX: if TRUE, features will be centered and scaled; note that
#        this means the features must be numeric
#     smoothingFtn: as in kNN(); 'mean' or 'loclin'
#     expandVars,expandVals:  e.g. expandVars element = 3 and
#        expandVals = 0.2 means give variable 3 a weight of 0.2
#        instead of 1.0 in the distance function

# value:  see above

# see note in kNN() man pg
 
qeLogitKNN <- function(data,yName,k=25,scaleX=TRUE,
   smoothingFtn=mean,expandVars=NULL,expandVals=NULL,
   holdout=floor(min(1000,0.1*nrow(data))),yesYVal=NULL)
{
   classif <- is.factor(data[[yName]])
   if (!classif) stop('classification case')
   ycol <- which(names(data) == yName)
   lvlsY <- levels(data[,ycol])
   if (length(lvlsY) != 2)
      stop('2-class case only')
   if (is.null(yesYVal)) {
      yesYVal <- lvlsY[1]
      noYVal <- lvlsY[2]
   } else {
      yesyval <- which(lvlsY == yesYVal)
      noYVal <- lvlsY[3-yesYVal]
   }
   frml <- as.formula(paste0(yName,' ~ .'))
   if (!is.null(holdout)) {
      hIdxs <- sample(1:nrow(data),holdout)
      trn <- data[-hIdxs,]
      tst <- data[hIdxs,]
   } else {
      hIdxs <- NULL
      trn <- data
   }
   logitout <- glm(frml,data=trn,family=binomial)
   dataForKNN <- trn
   dataForKNN[ycol] <- logitout$y - logitout$fitted.values
   knnout <- qeKNN(dataForKNN,yName,k=k,holdout=NULL)
   linknnout <- list(logitout=logitout,knnout=knnout,classif=classif,
      yesYVal=yesYVal,noYVal)
   class(linknnout) <- 'qeLogitKNN'

   if (!is.null(holdout)) {
      predictHoldout(linknnout)
      linknnout$holdIdxs <- hIdxs
   } else linknnout$holdIdxs <- NULL
   linknnout
}

predict.qeLogitKNN <- function(object,newx,newxK=1,...)
{
   classif <- object$classif
   if (!classif) stop('for classification problems')
   logitout <- object$logitout
   logitPreds <- predict(logitout,newx)
   knnout <- object$knnout
   knnPreds <- predict(knnout,newx,newxK=newxK)
   probs <- logitPreds + knnPreds
   probs <- pmin(probs,1)
   probs <- pmax(probs,0)
   y01s <- round(probs)
   predClasses <- y01s
   predClasses[probs >= 0.5] <- object$yesYVal
   predClasses[probs < 0.5] <- object$noYVal
   lists(predClasses=predClasses,probs=probs)

}

