
module equities

using ComponentArrays
using Distributions # for MvNormal
using Printf
using Random


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


function scenario(params,Z;months=1200)
    # loop through the funds
	
	# (;σ_v,σ_0, ρ,A,B,C) = params

	

	# n_funds = size(params,2)
	n_funds = length(params.names)
    return n_funds
	
	#initilize/pre-allocate
	# Zₜ = rand(Z) # an 11 element vector of random numbers, drawn to be correlated, reflecting 11 items in corr matrix
	# v_t = log.(σ_0) # 4 element vector based on parameters, one per fund
	# σ_t = zeros(n_funds) # 4 element vector, one per fund
	# μ_t = zeros(n_funds) # 4 element vector, one per fund
	
	# # this mapping looks like the thing to speed up
	# log_returns = map(1:months) do t # why do we do this over 10 months??; nevermind - looks like it's over 1200 generally, 10 was a test
	# 	Zₜ = rand!(Z,Zₜ) # a replacement set of 11 random numbers 0.000012 
	# 	v_t .= v(v_t,params,Zₜ) # 4-element replacement vector 0.000018 seconds (9 allocations: 704 bytes)

	# 	σ_t .= exp.(v_t) # 4-element replacement vector 0.000014 seconds (2 allocations: 32 bytes)

	# 	@. μ_t =  A + B * σ_t + C * (σ_t)^2 # 4-element replacement vector 0.000029 seconds (10 allocations: 688 bytes)
	# 	# @time temp =  A + B .* σ_t + C .* (σ_t).^2 # maybe slightly slower

	# 	# equity returns are the even values in the random array -- a 4-element vector -- this is what takes the most time, BEFORE compilation
	# 	# @time log_return = @. μ_t / 12 + σ_t / sqrt(12) * Zₜ[[2,4,6,8]]  # 0.013997 seconds (17.36 k allocations: 1017.116 KiB, 99.72% compilation time)
	# 	# log_return = μ_t / 12 + σ_t / sqrt(12) .* Zₜ[[2,4,6,8]]  # this is about 1/3 faster		
	# 	_ = μ_t / 12 + σ_t / sqrt(12) .* Zₜ[[2,4,6,8]]  # this is about 1/3 faster		
	# 	# @time tmp = μ_t / 12 + σ_t / sqrt(12) .* Zₜ[[2,4,6,8]]  # this is about 1/3 faster
	# 	# after compilation: 0.000034 seconds (11 allocations: 576 bytes)
	# end

	# # convert vector of vector to matrix
	# reduce(hcat,log_returns) # figure out what this is doing??		
end # function


function loop(params; months=1200)

    # extract equities
    # println(params.names)
   # a = 0.0 # pre-allocate
   
   # consider speed for
   #   writing after each sim
   #   writing after all sims for a given fund -- about 96mb -- seems like it should be faster
    
    for name in params.names
        # println(name)
        # println(params.funds[name])
        (;τ, σ_v, σ_0, ρ, A, B, C) = params.funds[name]
        for sim in 1:10000
            for month in 1:months
                a = exp(ρ)
            end
        end
        # @printf "tau = %0.3f\n" params.funds[name].τ
        # @printf "rho = %0.3f\n" params.funds[name].ρ
        # @printf "tau = %0.3f\n" params.funds[name].τ
        # @printf "rho = %0.3f\n" params.funds[name].ρ

    end 


end # function loop


function loop2(params; months=1200)

    # extract equities
    println(params.names)

    for name in params.names
        # println(name)
        # println(@view params.funds[name])
        @view params.funds[name]
        # println(params.funds[name])
        # @printf "tau = %0.3f\n" vals[fund].τ
        # @printf "rho = %0.3f\n" vals[fund].ρ
    end 


end # function loop


end # module