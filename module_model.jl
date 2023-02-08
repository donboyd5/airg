

module model

using ComponentArrays
using Distributions
using Printf
using Random

include("module_equities2.jl")
import .equities

# interest rates
# stcurve = [0.01, 0.02, 0.024, 0.03, 0.04, 0.05, 0.055, 0.06, 0.07, 0.08] # starting yield curve
# intrates.scenario(stcurve, x.rates)
# intrates.scenario(stcurve, x.rates, months=24)


function loop(params; sims=10, months=12)
   
    # consider speed for
    #   writing after each sim
    #   writing after all sims for a given fund -- about 96mb -- seems like it should be faster
 
    Z = MvNormal(
     # define random numbers we will get
     # we will need 11 sets of correlated random numbers, one per column of the covariance (correlation) matrix, which includes not just correlations
     # of returns, but also of volatilities
     zeros(11), # means for return and volatility
     params.covmatrix # covariance matrix
     # full covariance matrix in AAA Excel workook on Parameters tab
     ) 
     
    # preallocate the vector of 11 items; use ComponentArray so that we can refer to elements with meaningful symbols
    Zₜ = ComponentArray(rand(Z), params.covmat_axis) # preallocate
 
     for sim in 1:sims
        # do NOT loop through months here - rather, let each asset type loop through months, because an asset type may have
        # correlations across months so it needs to control that
         for month in 1:months
            # get the rand
            Zₜ = rand!(Z, Zₜ) # refill Zₜ with 11 new random normal values per the covariance matrix
            # rather than looping? call each fund with the approprirate params? or maybe look

            # interest rates

            
             for name in params.equities.names
                 print(name,", ")
                 print("usstocks_vol: ")
                 println("abc ", Zₜ.usstocks_vol)
                 # println(params.funds[name])
                 # (;τ, σ_v, σ_0, ρ, A, B, C) = params.equities.funds[name]            
                 # @unpack τ, σ_v, σ_0, ρ, A, B, C = params.equities.funds[name]            
                 # slv(params.equities.funds[name])
                 # call each 
                 # at what point should we write results??
             end # name
             println()
         end # months
     end # sims    
 
 end # function loop

end # module