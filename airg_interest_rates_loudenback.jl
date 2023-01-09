
begin 
    using Random
    using UnPack
	using Plots
	using Statistics
	using ActuaryUtilities
	using ThreadsX # for easy multithreading
end


# AAA ESG Exploration Tool
# This reactive notebook explores the sensitivity of the American Academy of Actuaries' (AAA) [Economic Scenario Generator (ESG)](https://www.actuary.org/content/economic-scenario-generators) to changing parameters.  

# ```julia
# α_τ =(1-β₂) * α_τ + β₂ * τ₂ + ϕ * (log(r₁) - log(τ₁)) + σ₂ * shock_short * r₁^θ
# ```



## Interactive ESG
### Interactive Parameters:
# Number of Scenarios: <input type='number' min='1' max='5' value='200' />
# τ₁ Long Term Mean Reversion Point <input type='range' min='0.0' max='0.1' value='0.035' step='0.005'
# <label id='fPrice'>0.035</label>
τ₁ = 0.035 # djb; note that soa now uses .0325


#  vol Process Volatility <input type='range' min='0.05' max='0.3' value='0.11489' step='0.005'
#	oninput=\"document.getElementById('fPrice').innerHTML = this.value\" />
#        <label id='fPrice'>0.11489</label>
vol = 0.11489 # djb


### Scenario Visualization"
#### Long Rate Statistics:

# Notebook Details
# The following cells contain the code that generates the parameters and scenarios

# The starting curve is based on 12/31/2020:

start_curve = [0.0155, 0.0160, 0.0159, 0.0158, 0.0162, 0.0169, 0.0183, 0.0192, 0.0125, 0.0239]

# this is a function which takes a couple of input parameters and returns a named 
# tuple with all of the required parameters for the AAA ESG
full_params(τ₁=0.035,vol=0.11489
	) = (
	τ₁ = τ₁,   # Long term rate (LTR) mean reversion; djb: soa now uses .0325
	β₁ = 0.00509, # Mean reversion strength for the log of the LTR
	θ = 1,
	τ₂ = 0.01,    # Mean reversion point for the slope
	β₂ = 0.02685, # Mean reversion strength for the slope
	σ₂ = 0.04148, # Volatitlity of the slope
	τ₃ = 0.0287,  # mean reversion point for the vol of the log of LTR
	β₃ = 0.04001, # mean reversion strength for the log of the vol of the log of LTR
	σ₃ = vol, # vol of the stochastic vol process
	ρ₁₂ = -0.19197, # correlation of shocks to LTR and slope (long - short)
	ρ₁₃ = 0.0,  # correlation of shocks to long rate and volatility
	ρ₂₃ = 0.0,  # correlation of shocks to slope and volatility
	ψ = 0.25164,
	ϕ = 0.0002,
	r₂_min = 0.01, # soft floor on the short rate
	r₂_max = 0.4, # unused - maximum short rate
	r₁_min = 0.015, # soft floor on long rate before random shock; djb soa uses .0115
	r₁_max = 0.18, # soft cap on long rate before random shock
	κ = 0.25, # unused - when the short rate would be less than r₂_min it was κ * long 
	γ = 0.0, # unused - don't change from zero
	σ_init = 0.0287,
	months = 12 * 30,  # djb - make number of years a parameter so that it can be matched with # of years for equities
	rate_floor = 0.0001, # absolute rate floor
	maturities = [0.25,0.5,1,2,3,5,7,10,20,30],
)

params = full_params(τ₁,vol)


# This replicates the American Academy of Actuaries' scenario generator v7.1.202005
function scenario(start_curve,params)
	
	# unpack the params into the named variables
    @unpack τ₁,β₁,θ,τ₂,β₂,σ₂,τ₃,β₃,σ₃,ρ₁₂,ρ₁₃,ρ₂₃,ψ,ϕ,r₂_min,r₂_max,r₁_min,r₁_max,κ,γ,σ_init,months,rate_floor,maturities = params
	
    # some constants
	const1 =  √(1-ρ₁₂^2)
	const2 = (ρ₂₃-ρ₁₂*ρ₁₃)/(const1)
	const3 = √(1-((ρ₂₃ - ρ₁₂*ρ₁₃)^2)/(1ρ₁₂^2)-ρ₁₃^2)
	const4 = β₃ * log(τ₃)
	const5 = β₁ * log(τ₁)
	
	# Nelson Siegel interpolation factors
	ns_interp = [(1 - exp(-0.4 * m)) / ( 0.4 * m) for m in maturities]
	
	
	# containers for hot values
	rates = zeros(months,10) # allocate initial 
	shock = zeros(3)
	ns_fitted = zeros(10)
	
	# initial values
	v_τ = log(σ_init) # long rate log vol
	σ_longvol = σ_init
	α_τ = start_curve[9]-start_curve[3]
	pertubation = 1.0
	
	r₁ = start_curve[9]
	r₂ = max(r₂_min,start_curve[3])
    
    b₁ = (r₂ - r₁) / (ns_interp[3] - ns_interp[9])
    b₀ = r₂ - b₁ * ns_interp[3]

	
	ns_fitted .= b₀ .+ b₁ .* ns_interp 
	start_diff = ns_fitted .- start_curve 
	
	for month in 1:months

		## Correlated Normals
        randn!(shock)
        # shock .= norms'[:,month]
		shock_long  = shock[1]
		shock_short = shock[1] * ρ₁₂ + shock[2] * const1
		shock_vol   = shock[1] * ρ₁₃ + shock[2] * const2 + shock[3] * const3
			
		## Generator Process
		v_τ =(1-β₃) * v_τ + const4 + σ₃ * shock_vol
		σ_longvol = exp(v_τ)
		
        # moved this after r₁ because it uses the prior val
        
        
        α_τ_prior = α_τ
        α_τ =(1-β₂) * α_τ + β₂ * τ₂ + ϕ * (log(r₁) - log(τ₁)) + σ₂ * shock_short * r₁^θ
		
        ## Generator Results
        
        r_pre = (1-β₁)*log(r₁)+const5+ψ*(τ₂-α_τ_prior)
		r₁ = exp(clamp(r_pre,log(r₁_min),log(r₁_max)) + σ_longvol * shock_long)
		
		
		r₂ = max(r₁ - α_τ,r₂_min)
        
        
		## Nelson-Siegel Fitted Curve
		ns_fitted .= b₀ .+ b₁ .* ns_interp
		
        b₁ = (r₂ - r₁) / (ns_interp[3] - ns_interp[9])
        b₀ = r₂ - b₁ * ns_interp[3]
        
        ## Fully Interpolated Curve
		
		rates[month,:] .= max.(rate_floor, ns_fitted .- pertubation .* start_diff)
		
		# Update values for next loop
		pertubation = max(0.0,pertubation - 1/12)

	end
	
	return rates
end


n_scenarios = 5 # djb
@time scenarios = ThreadsX.map(i -> scenario(start_curve,params), 1:n_scenarios);
# @time scenarios2 = map(i -> scenario(start_curve,params), 1:n_scenarios); # djb unthreaded is slightly faster (why??)
size(scenarios) # djb (n_scenarios, )


## plots below here

# note that the CTE function requires ActuaryUtilities v2.1 or higher

# djb re CTE
# https://www.soa.org/globalassets/assets/library/newsletters/risk-management-newsletter/2004/july/rm-2004-iss02-ingram-b.pdf
# The risk measure conditional tail expectation (CTE) has been getting more and # more attention for measuring risk in any
# situation with non-normal distribution of losses. Canadian and U.S. insurance regulators have adopted CTE as a standard
# for regulatory capital measurement. Academics have lauded CTE as a “coherent” statistic. Those outside the insurance 
# industry call it “Tail VaR” or “expected tail loss” (ETL). Actuaries, who have always been suspicious or even hostile
# to the usage of value at risk (VaR) as a risk measurement standard, have readily embraced CTE.

let
	# average and CTE70 and CTE98 of 20 year rates
	stats = ThreadsX.map(s -> (
			mean= mean(s[:,9]),
			CTE70=CTE(s[:,9],.7,rev=true),
			CTE98=CTE(s[:,9],.98,rev=true)
			),scenarios)
	h1 = histogram(
		[x.mean for x in stats],  
		label="",
		orientation = :horizontal,
		alpha=0.5,
		ylim = (0.,.1),
		ylabel="20-Year Interset Rate",
		xlim=(0,(n_scenarios ÷ 20)),
		xtick=:none,
		grid=false,
		title="Mean",
		bins = 0.:0.0025:.1,
	)
 		h2 = histogram(
		[x.CTE70 for x in stats],
		alpha=0.5,
		title="CTE70",
		label="",
		ylim = (0.,.1),
		xlim=(0,(n_scenarios ÷ 20)),
		xtick=:none,
		ytick=:none,
		orientation = :horizontal,
		bins = 0.:0.0025:.1,
	)
	 	h3 = histogram(
		[x.CTE98 for x in stats],
		alpha=0.5,
		title="CTE98",
		label="",
		ylim = (0.,.1),
		xlim=(0,(n_scenarios ÷ 20)),
		xtick=:none,
				ytick=:none,
		orientation = :horizontal,
		
		bins = 0.:0.0025:.1,
	)
	plot([h1,h2,h3]...,layout=(1,3))
end

let
 	p = plot(legend=false,title="Long Rate Paths",ylim=(0,.15))

 	for s in scenarios
 		plot!(p,s[:,9], color=:blue, alpha=0.05)
 	end
 	p
 end

scenarios[1]
tmp = scenarios[2]
size(scenarios)

plot(sum(hcat([s[:,10] for s in scenarios]...),dims=2) ./ n_scenarios)
