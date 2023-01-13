
module equities

# https://www.matecdev.com/
# based on code by Alec Loudenback, here: https://github.com/JuliaActuary/Learn/blob/master/AAA_Equity_Generator.jl

# equity parameters
# tau         Long run target volatility
# phi         Strength of mean reversion
# sigma(v)    Monthly std deviation of the log volatility process
# rho	      Correlation between random shock to vol and random component of return
# A	          Stock return at zero volatility
# B	          Coefficient in quadratic function for mean return (function of volatility)
# C	          Coefficient in quadratic function for mean return (function of volatility)
# sigma(0)    Starting volatility
# sigma-	  Minimum volatility (annualized)
# sigma+	  Maximum volatility (annualized, before random component)
# sigma*	  Maximum volatility (annualized, after random component)



# md" Initial attempt to replicate AAA equtity generator. 
# Reference: [https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf](https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf)"


end