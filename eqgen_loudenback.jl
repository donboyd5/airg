
# this is based on code by Alec Loudenback, here: https://github.com/JuliaActuary/Learn/blob/master/AAA_Equity_Generator.jl

using Distributions
using Random
using RandomNumbers
using LabelledArrays


# md" Initial attempt to replicate AAA equtity generator. 
# Todo for prototype:
# - The summary statistics don't match the paper for the US diversified equity
#   - potentially caused by incorrect correlation matrix? what should be the 1st entry?
# Reference: [https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf](https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf)"


# md"## Model Parameters"
# use a labelled array for easy reference of the parameters 
# the 4 columns are equity parameters for the funds:
#   US Diversified, Int'l Diversified, Intermed Risk, Aggressive / Exotic
params = @LArray [
    0.12515 0.14506 0.16341 0.20201 # τ tau
    0.35229 0.41676 0.3632 0.35277 # ϕ phi
    0.32645 0.32634 0.35789 0.34302 # σ_v
    -0.2488 -0.1572 -0.2756 -0.2843 #ρ
    0.055 0.055 0.055 0.055 # A
    0.56 0.466 0.67 0.715 # B
    -0.9 -0.9 -0.95 -1.0 #C
    0.1476 0.1688 0.2049 0.2496 # σ_0
    0.0305 0.0354 0.0403 0.0492 # σ_m
    0.3 0.3 0.4 0.55 # σ_p
    0.7988 0.4519 0.9463 1.1387 # σ⃰
] ( # define the regions each label refers to
	τ = (1,:),
	ϕ = (2,:),
	σ_v = (3,:),
	ρ = (4,:),
	A = (5,:),
	B = (6,:),
	C = (7,:),
	σ_0 = (8,:),
	σ_m = (9,:),
	σ_p = (10,:),
	σ⃰ = (11,:)
)

# params[1, :] # row 1, which is τ tau
# params[2, :] # row 2, ϕ phi
# params.ϕ

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


# (;σ_v, σ_m,σ_p,σ⃰,ϕ,τ) = params

# σ_v

# md"## Stochastic Log Volatility Model
# Note that the `@.` and other broadcasting (`.` symbol) allows us to operate on multiple funds at once.

function v(v_prior,params,Zₜ) 
	(;σ_v, σ_m,σ_p,σ⃰,ϕ,τ) = params
	
	v_m = log.(σ_m)
	v_p = log.(σ_p)
	v⃰ = log.(σ⃰)

	# vol are the odd values in the random array
	ṽ =  @. min(v_p, (1 - ϕ) * v_prior + ϕ * log(τ) ) + σ_v * Zₜ[[1,3,5,7]]
	
	v = @. max(v_m, min(v⃰,ṽ))

	return v
end


function scenario(params,Z;months=1200)
	# why does Alec set months=10 when he calls scenario below???
	(;σ_v,σ_0, ρ,A,B,C) = params

	n_funds = size(params,2)
	
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
	end

	# convert vector of vector to matrix
	reduce(hcat,log_returns) # figure out what this is doing??		
end

# md" ## Scenarios and validation
### A single scenario"

# md"### Validation of summary statistics"

# md"The summary statistics expected (per paper Table 8):
# - `μ ≈ [0.0060, 0.0062, 0.0063, 0.0065]`
# - `σ ≈ [0.0436, 0.0492, 0.0590, 0.0724]`

# md"## The Multivariate normal and covariance matrix"

# 11 columns because it's got the bond returns in it
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

# the 11 elements of the matrix, in order, are
# US LogVol, US LogRet, Int'l LogVol, Int'l LogRet, Small LogVol, Small LogRet, Aggr LogVol, Aggr LogRet, Money Ret, IT Govt Ret, LTCorp Ret
# so logvols are in indexes 1, 3, 5, 7 -- US, Int'l, Small, Aggr
# and log rets are in 2, 4, 6, 8, 9, 10, 11 -- US, Int'l, Small, Aggr, Money, IT Govt, LT Corp

Z = MvNormal(
    zeros(11), # means for return and volatility
    cov_matrix # covariance matrix
    # full covariance matrix in AAA Excel workook on Parameters tab
)



# rand!([rng=GLOBAL_RNG], A, [S=eltype(A)]) # Populate the array A with random values. 

# x = scenario(params,Z;months=12) # this must be a test; he used 10
# returns a 4 x 12 matrix - 12 months wide, 4 funds long

# @btime scenario(params,Z;months=1200) 

n = 10000

@time let
	# generate 1000 scenarios and calculate summary statisics
		scens = [scenario(params,Z) for _ in 1:n]
		μ = mean(mean(x,dims=2) for x in scens)
		σ = mean(std(x,dims=2) for x in scens)
		(;μ,σ)
end  # when n=10000 takes a bit over 30 seconds, scens takes all the time


# djb = function(n)
# 	scens = [scenario(params,Z) for _ in 1:n]
	
# 	μ = mean(mean(x,dims=2) for x in scens)
# 	σ = mean(std(x,dims=2) for x in scens)
# 	return (;μ,σ)
# end

# @time stats = djb(10000)

# @time tmp = scenario(params,Z)


# # md"The summary statistics expected (per paper Table 8):
# # - `μ ≈ [0.0060, 0.0062, 0.0063, 0.0065]`
# # - `σ ≈ [0.0436, 0.0492, 0.0590, 0.0724]`
# # (μ = [0.006066600818810306; 0.006168060536723953; 0.006239802214447253; 0.006527862607266217;;], σ = [0.0435129420241672; 0.04919214950566403; 0.059027558678831596; 0.07223838015089827;;])
# # (μ = [0.006075997403873153; 0.006246239324236695; 0.006330705205404062; 0.006514216939880671;;], σ = [0.04357929229983008; 0.04908522071196592; 0.0589234723545177; 0.0722355415420798;;])
# # (μ = [0.0060828007274449265; 0.0062022370816064735; 0.006316783702895471; 0.006510257409151889;;], σ = [0.043574515557511725; 0.04912498441447454; 0.05904807500393901; 0.07225325918577571;;])
# # (μ = [0.0060717558255266955; 0.006202695417613852; 0.006297878925718058; 0.0065043612995511115;;], σ = [0.043589209181370984; 0.049141121867023616; 0.059041082489402014; 0.07229867770776659;;])

# f1(rows=1000, cols=1000) = rand(Float64, (rows, cols))

# function f2(rows=1000, cols=1000)
# 	# M = Matrix{RGB{Float32}}(undef, 1080, 1980)
# 	# rows = 1000
# 	# cols = 1000
# 	M = Array{Float64}(undef, rows, cols)
# 	@inbounds for j in 1:cols
# 		for i in 1:rows
# 			M[i,j] = rand()
# 		end
# 	end
# 	return M
#  end

#  function f2a(rows=1000, cols=1000)
# 	# M = Matrix{RGB{Float32}}(undef, 1080, 1980)
# 	# rows = 1000
# 	# cols = 1000
# 	M = Array{Float64}(undef, rows, cols)
# 	for j in 1:cols
# 		for i in 1:rows
# 			M[i,j] = rand()
# 		end
# 	end
# 	return M
#  end



# function f3(rows, cols)
# 	M = Array{Float64}(undef, rows, cols)
# 	@. M = rand()
# 	return M
#  end

#  @btime f1(5000, 5000); #  1.096 ms (2 allocations: 7.63 MiB);fastest, by a little
#  @btime f2(5000, 5000); # 1.323 ms (2 allocations: 7.63 MiB)
#  @btime f2a(5000, 5000);
#  @btime f3(5000, 5000);


#  rng = Random.default_rng()
#  function f4(rng, rows, cols)
# 	# M = Matrix{RGB{Float32}}(undef, 1080, 1980)
# 	M = Array{Float64}(undef, rows, cols)
# 	# @. M = RGB(rand(rng), rand(rng), rand(rng))
# 	# @. M = rand(rng, (rows, cols))
# 	@. M = rand(rng)
# 	# @inbounds for j in 1:cols
# 	# 	for i in 1:rows
# 	# 		M[i,j] = rand()
# 	# 	end
# 	# end
# 	return M
#  end

#  rng = Random.default_rng()
#  rng_xor = RandomNumbers.Xorshifts.Xoroshiro128Star()
#  @btime f4($rng, 1000, 1000);   1.352 ms (2 allocations: 7.63 MiB)
#  @btime f4($rng_xor, 1000, 1000);


#  M = Array{Float64}(undef, 5, 5)
# M

# @.M = rand()




## Timings

# # md"The summary statistics expected (per paper Table 8):
# # - `μ ≈ [0.0060, 0.0062, 0.0063, 0.0065]`
# # - `σ ≈ [0.0436, 0.0492, 0.0590, 0.0724]`


# @time let
# 	# generate 1000 scenarios and calculate summary statisics
# 			scens = [scenario(params,Z) for _ in 1:n]
# 			μ = mean(mean(x,dims=2) for x in scens)
# 			σ = mean(std(x,dims=2) for x in scens)
# 			(;μ,σ)
#    end  # when n=10000 takes a bit over 30 seconds, scens takes all the time
# 27.419465 seconds (264.53 M allocations: 18.004 GiB, 5.70% gc time, 0.20% compilation time)
# (μ = [0.0061019327283056415; 0.0062136553876007234; 0.006341519452650646; 0.006587062692634892;;], σ = [0.04354989454600793; 0.049153052059467205; 0.05900229959306076; 0.0722207719467681;;])

# julia> @time stats = loop_scenarios(10000, params)
#  28.600454 seconds (264.43 M allocations: 17.999 GiB, 5.57% gc time)
# (μ = [0.006059426936364462; 0.006194791309762255; 0.00629701907611931; 0.006500116462469036;;], σ = [0.043600147983650264; 0.04915498160171715; 0.05902083187935057; 0.07227054983082762;;])

# julia> @time stats = loop_scenarios(10000, params_LA)
#  28.028296 seconds (264.43 M allocations: 17.999 GiB, 5.79% gc time)
# (μ = [0.006088069038537702; 0.00621719999236229; 0.006320418952082233; 0.0064812334995546185;;], σ = [0.04357643164220039; 0.04915171978823114; 0.05902770226835611; 0.07236101059392772;;])

# 10,000 100-year monthly scenarios takes about 20 minutes, including interest rates, and csv file writing, in Excel

