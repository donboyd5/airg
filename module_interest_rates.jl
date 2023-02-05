
module intrates

#=
Based heavily on Alec Loudenback's code
  https://github.com/JuliaActuary/Learn/blob/master/AAA_ESG.jl

=#


using ComponentArrays
using Random


# This replicates the American Academy of Actuaries' scenario generator v7.1.202005
function scenario(start_curve, params; months=1200)

    # unpack the params into the named variables
    (; τ₁, β₁, θ,
        τ₂, β₂, σ₂,
        τ₃, β₃, σ₃,
        ρ₁₂, ρ₁₃, ρ₂₃,
        ψ, ϕ, r₂_min, r₂_max, r₁_min, r₁_max,
        κ, γ, σ_init, rate_floor, maturities) = params

    #  τ₁,β₁,θ,τ₂,β₂,σ₂,τ₃,β₃,σ₃,ρ₁₂,ρ₁₃,ρ₂₃,ψ,ϕ,r₂_min,r₂_max,r₁_min,r₁_max,κ,γ,σ_init,months,rate_floor,maturities = params

    months = convert(Int64, months) # months is used to size the rates array and so must be integer

    # Random.seed!(123)  # temporary, to control results

    # some constants
    const1 = √(1 - ρ₁₂^2)
    const2 = (ρ₂₃ - ρ₁₂ * ρ₁₃) / (const1)
    const3 = √(1 - ((ρ₂₃ - ρ₁₂ * ρ₁₃)^2) / (1ρ₁₂^2) - ρ₁₃^2)
    const4 = β₃ * log(τ₃)
    const5 = β₁ * log(τ₁)

    # Nelson Siegel interpolation factors
    ns_interp = [(1 - exp(-0.4 * m)) / (0.4 * m) for m in maturities]


    # containers for hot values
    rates = zeros(months, 10) # allocate initial 
    shock = zeros(3)
    ns_fitted = zeros(10)

    # initial values
    v_τ = log(σ_init) # long rate log vol
    σ_longvol = σ_init
    α_τ = start_curve[9] - start_curve[3]
    pertubation = 1.0

    r₁ = start_curve[9]
    r₂ = max(r₂_min, start_curve[3])

    b₁ = (r₂ - r₁) / (ns_interp[3] - ns_interp[9])
    b₀ = r₂ - b₁ * ns_interp[3]


    ns_fitted .= b₀ .+ b₁ .* ns_interp
    start_diff = ns_fitted .- start_curve

    for month in 1:months

        ## Correlated Normals
        randn!(shock)
        # shock .= norms'[:,month]
        shock_long = shock[1]
        shock_short = shock[1] * ρ₁₂ + shock[2] * const1
        shock_vol = shock[1] * ρ₁₃ + shock[2] * const2 + shock[3] * const3

        ## Generator Process
        v_τ = (1 - β₃) * v_τ + const4 + σ₃ * shock_vol
        σ_longvol = exp(v_τ)

        α_τ_prior = α_τ
        α_τ = (1 - β₂) * α_τ + β₂ * τ₂ + ϕ * (log(r₁) - log(τ₁)) + σ₂ * shock_short * r₁^θ

        ## Generator Results        
        r_pre = (1 - β₁) * log(r₁) + const5 + ψ * (τ₂ - α_τ_prior)
        r₁ = exp(clamp(r_pre, log(r₁_min), log(r₁_max)) + σ_longvol * shock_long)


        r₂ = max(r₁ - α_τ, r₂_min)


        ## Nelson-Siegel Fitted Curve
        ns_fitted .= b₀ .+ b₁ .* ns_interp

        b₁ = (r₂ - r₁) / (ns_interp[3] - ns_interp[9])
        b₀ = r₂ - b₁ * ns_interp[3]

        ## Fully Interpolated Curve

        rates[month, :] .= max.(rate_floor, ns_fitted .- pertubation .* start_diff)

        # Update values for next loop
        pertubation = max(0.0, pertubation - 1 / 12)

    end

    return rates
end

end # module


# here's Alec's function
# This replicates the American Academy of Actuaries' scenario generator v7.1.202005
# function scenario(start_curve,params)
	
# 	# unpack the params into the named variables
#     @unpack τ₁,β₁,θ,τ₂,β₂,σ₂,τ₃,β₃,σ₃,ρ₁₂,ρ₁₃,ρ₂₃,ψ,ϕ,r₂_min,r₂_max,r₁_min,r₁_max,κ,γ,σ_init,months,rate_floor,maturities = params
	
#     # some constants
# 	const1 =  √(1-ρ₁₂^2)
# 	const2 = (ρ₂₃-ρ₁₂*ρ₁₃)/(const1)
# 	const3 = √(1-((ρ₂₃ - ρ₁₂*ρ₁₃)^2)/(1ρ₁₂^2)-ρ₁₃^2)
# 	const4 = β₃ * log(τ₃)
# 	const5 = β₁ * log(τ₁)
	
# 	# Nelson Siegel interpolation factors
# 	ns_interp = [(1 - exp(-0.4 * m)) / ( 0.4 * m) for m in maturities]
	
	
# 	# containers for hot values
# 	rates = zeros(months,10) # allocate initial 
# 	shock = zeros(3)
# 	ns_fitted = zeros(10)
	
# 	# initial values
# 	v_τ = log(σ_init) # long rate log vol
# 	σ_longvol = σ_init
# 	α_τ = start_curve[9]-start_curve[3]
# 	pertubation = 1.0
	
# 	r₁ = start_curve[9]
# 	r₂ = max(r₂_min,start_curve[3])
    
#     b₁ = (r₂ - r₁) / (ns_interp[3] - ns_interp[9])
#     b₀ = r₂ - b₁ * ns_interp[3]

	
# 	ns_fitted .= b₀ .+ b₁ .* ns_interp 
# 	start_diff = ns_fitted .- start_curve 
	
# 	for month in 1:months

# 		## Correlated Normals
#         randn!(shock)
#         # shock .= norms'[:,month]
# 		shock_long  = shock[1]
# 		shock_short = shock[1] * ρ₁₂ + shock[2] * const1
# 		shock_vol   = shock[1] * ρ₁₃ + shock[2] * const2 + shock[3] * const3
			
# 		## Generator Process
# 		v_τ =(1-β₃) * v_τ + const4 + σ₃ * shock_vol
# 		σ_longvol = exp(v_τ)
		
#         # moved this after r₁ because it uses the prior val
        
        
#         α_τ_prior = α_τ
#         α_τ =(1-β₂) * α_τ + β₂ * τ₂ + ϕ * (log(r₁) - log(τ₁)) + σ₂ * shock_short * r₁^θ
		
#         ## Generator Results
        
#         r_pre = (1-β₁)*log(r₁)+const5+ψ*(τ₂-α_τ_prior)
# 		r₁ = exp(clamp(r_pre,log(r₁_min),log(r₁_max)) + σ_longvol * shock_long)
		
		
# 		r₂ = max(r₁ - α_τ,r₂_min)
        
        
# 		## Nelson-Siegel Fitted Curve
# 		ns_fitted .= b₀ .+ b₁ .* ns_interp
		
#         b₁ = (r₂ - r₁) / (ns_interp[3] - ns_interp[9])
#         b₀ = r₂ - b₁ * ns_interp[3]
        
#         ## Fully Interpolated Curve
		
# 		rates[month,:] .= max.(rate_floor, ns_fitted .- pertubation .* start_diff)
		
# 		# Update values for next loop
# 		pertubation = max(0.0,pertubation - 1/12)

# 	end
	
# 	return rates
# end
