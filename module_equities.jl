
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
using Distributions # for MvNormal
using Random


# Z = MvNormal(
# 	# define random numbers we will get
# 	# we will need 11 sets of correlated random numbers, one per column of the covariance (correlation) matrix, which includes not just correlations
# 	# of returns, but also of volatilities
#     zeros(11), # means for return and volatility
#     cov_matrix # covariance matrix
#     # full covariance matrix in AAA Excel workook on Parameters tab
# )

# Stochastic Log Volatility Model
# Note that the `@.` and other broadcasting (`.` symbol) allows us to operate on multiple funds at once.

function v(v_prior,params,Zₜ) 
	# natural logarithm of annualized volatility in month t
	# v(t) = Max{v-minus, Min(v*, v-tilde(t))} see Table 5 of the March 2005 documentation
	# The Z[[1, 3, 5, 7]] are the random values for correlated log volatilities, for 4 asset classes
	(;σ_v, σ_m,σ_p,σ⃰,ϕ,τ) = params
	
	v_m = log.(σ_m)
	v_p = log.(σ_p)
	v⃰ = log.(σ⃰)

	# vol are the odd values in the random array
	ṽ =  @. min(v_p, (1 - ϕ) * v_prior + ϕ * log(τ) ) + σ_v * Zₜ[[1,3,5,7]]
	
	v = @. max(v_m, min(v⃰,ṽ))

	return v
end


function scenario(params,covmatrix;months=1200)
	
	(;σ_v,σ_0, ρ,A,B,C) = params

    Z = MvNormal(
	# define random numbers we will get
	# we will need 11 sets of correlated random numbers, one per column of the covariance (correlation) matrix, which includes not just correlations
	# of returns, but also of volatilities
    zeros(11), # means for return and volatility
    covmatrix # covariance matrix
    # full covariance matrix in AAA Excel workook on Parameters tab
    )	

	# n_funds = size(params,2)
	n_funds = 1 # size(params.τ)[1]
	
	#initilize/pre-allocate
	Zₜ = rand(Z) # an 11 element vector of random numbers, drawn to be correlated, reflecting 11 items in corr matrix
	v_t = log.(σ_0) # 4 element vector based on parameters, one per fund
	σ_t = zeros(n_funds) # 4 element vector, one per fund
	μ_t = zeros(n_funds) # 4 element vector, one per fund
	
	# this mapping looks like the thing to speed up
	log_returns = map(1:months) do t # why do we do this over 10 months??; nevermind - looks like it's over 1200 generally, 10 was a test
		Zₜ = rand!(Z,Zₜ) # a replacement set of 11 random numbers 0.000012 
		v_t .= v(v_t,params,Zₜ) # 4-element replacement vector 0.000018 seconds (9 allocations: 704 bytes)

		σ_t .= exp.(v_t) # 4-element replacement vector 0.000014 seconds (2 allocations: 32 bytes)

		@. μ_t =  A + B * σ_t + C * (σ_t)^2 # 4-element replacement vector 0.000029 seconds (10 allocations: 688 bytes)
		# @time temp =  A + B .* σ_t + C .* (σ_t).^2 # maybe slightly slower

		# equity returns are the even values in the random array -- a 4-element vector -- this is what takes the most time, BEFORE compilation
		# @time log_return = @. μ_t / 12 + σ_t / sqrt(12) * Zₜ[[2,4,6,8]]  # 0.013997 seconds (17.36 k allocations: 1017.116 KiB, 99.72% compilation time)
		log_return = μ_t / 12 + σ_t / sqrt(12) .* Zₜ[[2,4,6,8]]  # this is about 1/3 faster		
		# @time tmp = μ_t / 12 + σ_t / sqrt(12) .* Zₜ[[2,4,6,8]]  # this is about 1/3 faster
		# after compilation: 0.000034 seconds (11 allocations: 576 bytes)
	end # do

	# convert vector of vector to matrix
	reduce(hcat,log_returns) # figure out what this is doing??		
end # function

end # module


# default equity parameters
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