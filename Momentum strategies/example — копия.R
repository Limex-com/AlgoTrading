

library(quantmod)
library(data.table)

universe = c('SPY','TLT','GLD','DBC','AGG','HYG','VNQ','EEM','EMB')

price = getSymbols('SPY',from='2008-01-01',auto.assign = F)
ret_matrix = dailyReturn(price[,4])


for(i in universe[2:9])
{
  price = getSymbols(i,from='2008-01-01',auto.assign = F)
  ret = dailyReturn(price[,4])
  ret_matrix = merge(ret_matrix,ret)
}

names(ret_matrix) = universe
View(ret_matrix)



pf_ew =  xts(rowMeans(ret_matrix),index(ret_matrix))

pf_allweather  =   xts(rowSums(0.3*ret_matrix$SPY+
                               0.4*ret_matrix$TLT+
                               0.15*ret_matrix$AGG+
                               0.075*ret_matrix$GLD+
                               0.075*ret_matrix$DBC),index(ret_matrix))
  
pf_6040 =  xts(rowSums(0.6*ret_matrix$SPY+0.4*ret_matrix$TLT),index(ret_matrix))

w_risk_parity = 1/apply(ret_matrix, 2, sd) / sum(1/apply(ret_matrix, 2, sd))

pf_risk_parity = xts(rowSums(sweep(ret_matrix, MARGIN=2,w_risk_parity, `*`)),index(ret_matrix))
#w_risk_parity*t(ret_matrix)


all_pf =  merge(pf_ew,pf_allweather,pf_6040,pf_risk_parity)
names(all_pf) = c('ew','allweather','6040','risk_parity')

library(PerformanceAnalytics)
charts.PerformanceSummary(all_pf)

SharpeRatio.annualized(all_pf['/2022'])
SharpeRatio.annualized(all_pf['2022/'])

View(w_risk_parity*t(dt_matrix))
as.matrix(ret_matrix) %*% t(as.matrix(w_risk_parity))
  


##### how to use apply ######### 
# apply(ret_matrix, 1, mean)
# apply(ret_matrix, 2, sd)
# apply(ret_matrix, 2, function(x) mean(x)/sd(x))
# myfunc = function(x) 
# {
#   mean(x)/sd(x)
# }
# myfunc(1:10)
# apply(ret_matrix, 2, myfunc)


library(PortfolioAnalytics)
library(ROI)
library(ROI.plugin.glpk)
library(ROI.plugin.quadprog)

pf = portfolio.spec(universe)
pf = add.constraint(pf,type = 'full_investment')
pf = add.constraint(pf,type = 'long_only')
pf = add.constraint(pf,type = 'box',min=0.02,max=0.3)
pf = add.constraint(pf,type = 'diversification', div_target=0.5)
#pf = add.constraint(pf,type='return',return_target=0.01)

pf = add.objective(pf,type="risk", name="ES")
#pf = add.objective(pf, type="return", name="mean")


opt_pf = optimize.portfolio(ret_matrix,pf,optimize_method="random")

#pf_optimal_return = xts(rowSums(sweep(ret_matrix, MARGIN=2,opt_pf$weights, `*`)),index(ret_matrix))
pf_optimal_risk = xts(rowSums(sweep(ret_matrix, MARGIN=2,opt_pf$weights, `*`)),index(ret_matrix) )



all_pf =  merge(pf_ew,pf_allweather,pf_6040,pf_risk_parity,pf_optimal_return,pf_optimal_risk)
names(all_pf) = c('ew','allweather','6040','risk_parity','return','risk')

library(PerformanceAnalytics)
charts.PerformanceSummary(all_pf[,4:6])



## optimize strategy ##


names(ret_matrix_xts) = LETTERS[1:ncol(ret_matrix_xts)]

pf = portfolio.spec(names(ret_matrix_xts))
pf = add.constraint(pf,type = 'full_investment')
pf = add.constraint(pf,type = 'long_only')
pf = add.constraint(pf,type = 'box',min=0.02,max=0.3)
pf = add.constraint(pf,type = 'diversification', div_target=0.5)
#pf = add.constraint(pf,type='return',return_target=0.01)
pf = add.objective(pf,type="risk", name="ES")
#pf = add.objective(pf, type="return", name="mean")

opt_pf = optimize.portfolio(ret_matrix_xts,pf,optimize_method="random")








