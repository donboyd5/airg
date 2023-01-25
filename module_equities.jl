
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


# equity parameters
# τ = [0.12515, 0.14506, 0.16341, 0.20201], # tau Long run target volatility
# ϕ = [0.35229, 0.41676, 0.3632, 0.35277],  # ϕ phi Strength of mean reversion
# σ_v = [0.32645, 0.32634, 0.35789, 0.34302], # σ_v Monthly std deviation of the log volatility process
# ρ = [-0.2488, -0.1572, -0.2756, -0.2843], # ρ Correlation between random shock to vol and random component of return
# A = [0.055, 0.055, 0.055, 0.055], # A Stock return at zero volatility
# B = [0.56, 0.466, 0.67, 0.715], # B Coefficient in quadratic function for mean return (function of volatility)
# C = [-0.9, -0.9, -0.95, -1.0], # C Coefficient in quadratic function for mean return (function of volatility)
# σ_0 = [0.1476, 0.1688, 0.2049, 0.2496], # σ_0 sigma(0) Starting volatility
# σ_m = [0.0305, 0.0354, 0.0403, 0.0492], # σ_m sigma minus Minimum volatility (annualized)
# σ_p = [0.3, 0.3, 0.4, 0.55], # σ_p sigma+ Maximum volatility (annualized, before random component)
# σ⃰ = [0.7988, 0.4519, 0.9463, 1.1387] # σ⃰ sigma* Maximum volatility (annualized, after random component)



# md" Initial attempt to replicate AAA equtity generator. 
# Reference: [https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf](https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf)"


end