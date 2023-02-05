
module equities

# https://www.matecdev.com/
# AIRG documentation https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf
# based partly on code by Alec Loudenback, here: https://github.com/JuliaActuary/Learn/blob/master/AAA_Equity_Generator.jl

# equity parameters
# symbol, name, description
# τ     tau         Long run target volatility
# ϕ     phi         Strength of mean reversion
# σ_v   sigma(v)    Monthly std deviation of the log volatility process
# ρ     rho         Correlation between random shock to vol and random component of return
# A     A           Stock return at zero volatility
# B     B           Coefficient in quadratic function for mean return (function of volatility)
# C	    C           Coefficient in quadratic function for mean return (function of volatility)
# σ_0   sigma(0)    Starting volatility
# σ_m   sigma-	    Minimum volatility (annualized)
# σ_p   sigma+	    Maximum volatility (annualized, before random component)
# σ⃰    sigma* 	    Maximum volatility (annualized, after random component)

using ComponentArrays


# build a named tuple for each fund type

# equity classes
usstocks=(
    τ=0.12515,
    ϕ=0.35229,
    σ_v=0.32645,
    ρ=-0.2488,
    A=0.055,
    B=0.56,
    C=-0.9,
    σ_0=0.1476,
    σ_m=0.0305,
    σ_p=0.3,
    σ⃰=0.7988)

intlstocks=(
    τ=0.14506,
    ϕ=0.41676,
    σ_v=0.32634,
    ρ=-0.1572,
    A=0.055,
    B=0.466,
    C=-0.9,
    σ_0=0.1688,
    σ_m=0.0354,
    σ_p=0.3,
    σ⃰=0.4519)

intrisk=(
    τ=0.16341,
    ϕ=0.3632,
    σ_v=0.35789,
    ρ=-0.2756,
    A=0.055,
    B=0.67,
    C=-0.95,
    σ_0=0.2049,
    σ_m=0.0403,
    σ_p=0.4,
    σ⃰=0.9463)

aggr=(
    τ=0.20201,
    ϕ=0.35277,
    σ_v=0.34302,
    ρ=-0.2843,
    A=0.055,
    B=0.715,
    C=-1,
    σ_0=0.2496,
    σ_m=0.0492,
    σ_p=0.55,
    σ⃰=1.1387)    

funds = ComponentArray((usstocks=usstocks, intlstocks=intlstocks, intrisk=intrisk, aggr=aggr))
fundnames = (:usstocks, :intlstocks, :intrisk, :aggr)

# The Multivariate normal and covariance matrix
# 11 columns because it's got the bond returns in it
# the 11 elements of the matrix, in order, are
# US LogVol, US LogRet, Int'l LogVol, Int'l LogRet, Small LogVol, Small LogRet, Aggr LogVol, Aggr LogRet, Money Ret, IT Govt Ret, LTCorp Ret
# so logvols are in indexes 1, 3, 5, 7 -- US, Int'l, Small, Aggr
# and log rets are in 2, 4, 6, 8, 9, 10, 11 -- US, Int'l, Small, Aggr, Money, IT Govt, LT Corp
cov_matrix = [
	1.000	-0.249	0.318	-0.082	0.625	-0.169	0.309	-0.183	0.023	0.075	0.080;
	-0.249	1.000	-0.046	0.630	-0.123	0.829	-0.136	0.665	-0.120	0.192	0.393;
	0.318	-0.046	1.000	-0.157	0.259	-0.050	0.236	-0.074	-0.066	0.034	0.044;
	-0.082	0.630	-0.157	1.000	-0.063	0.515	-0.098	0.558	-0.105	0.130	0.234;
	0.625	-0.123	0.259	-0.063	1.000	-0.276	0.377	-0.180	0.034	0.028	0.054;
	-0.169	0.829	-0.050	0.515	-0.276	1.000	-0.142	0.649	-0.106	0.067	0.267;
	0.309	-0.136	0.236	-0.098	0.377	-0.142	1.000	-0.284	0.026	0.006	0.045;
	-0.183	0.665	-0.074	0.558	-0.180	0.649	-0.284	1.000	0.034	-0.091	-0.002;
	0.023	-0.120	-0.066	-0.105	0.034	-0.106	0.026	0.034	1.000	0.047	-0.028;
	0.075	0.192	0.034	0.130	0.028	0.067	0.006	-0.091	0.047	1.000	0.697;
	0.080	0.393	0.044	0.234	0.054	0.267	0.045	-0.002	-0.028	0.697	1.000;
]


end


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