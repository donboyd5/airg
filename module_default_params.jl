module default_parameters

# functions to return default parameters as individual component arrays
# plus function to return all parameters as component array

using ComponentArrays

function default_rates()
    default_nt =
    (
        τ₁=0.0325,   # Long term rate (LTR) mean reversion; djb: soa now uses .0325
        β₁=0.00509, # Mean reversion strength for the log of the LTR
        θ=1, τ₂=0.01,    # Mean reversion point for the slope
        β₂=0.02685, # Mean reversion strength for the slope
        σ₂=0.04148, # Volatitlity of the slope
        τ₃=0.0287,  # mean reversion point for the vol of the log of LTR
        β₃=0.04001, # mean reversion strength for the log of the vol of the log of LTR
        σ₃=0.11489, # vol of the stochastic vol process
        ρ₁₂=-0.19197, # correlation of shocks to LTR and slope (long - short)
        ρ₁₃=0.0,  # correlation of shocks to long rate and volatility
        ρ₂₃=0.0,  # correlation of shocks to slope and volatility
        ψ=0.25164,
        ϕ=0.0002, r₂_min=0.01, # soft floor on the short rate
        r₂_max=0.4, # unused - maximum short rate
        r₁_min=0.015, # soft floor on long rate before random shock; djb soa uses .0115
        r₁_max=0.18, # soft cap on long rate before random shock
        κ=0.25, # unused - when the short rate would be less than r₂_min it was κ * long 
        γ=0.0, # unused - don't change from zero
        σ_init=0.0287,
        months=12 * 30,  # djb - make number of years a parameter so that it can be matched with # of years for equities
        rate_floor=0.0001, # absolute rate floor
        maturities=[0.25, 0.5, 1, 2, 3, 5, 7, 10, 20, 30],
    )
    return ComponentArray(default_nt)
end

function default_params(type="all")
    if type=="rates"
        return default_rates()
    end
end

end # end module