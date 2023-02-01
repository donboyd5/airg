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
        # months=12 * 30,  # djb - make number of years a parameter so that it can be matched with # of years for equities
        rate_floor=0.0001, # absolute rate floor
        maturities=[0.25, 0.5, 1, 2, 3, 5, 7, 10, 20, 30],
    )
    # ComponentArray(default_nt)
    return default_nt
end


function default_equities()
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

    equity_names = (:usstocks, :intlstocks, :intrisk, :aggr)    
    equity_array = ComponentArray(usstocks=usstocks, intlstocks=intlstocks, intrisk=intrisk, aggr=aggr)
    
    return ComponentArray(equity_names=equity_names, equity_array=equity_array)
end


function default_fixed()
    money = (m=0.25, β₀=0.08333, κ=-0.00445, β₁=-0.07148, σ=0.0037)
    intgov = (m=7, β₀=0.08333, κ=-0.00153, β₁=3.65043, σ=0.05239) # intermediate govt bonds
    longcorp = (m=10, β₀=0.08333, κ=0.00704, β₁=5.81293, σ=0.08282) # long corporate bonds

    # combine the above into a named tuple, and put it into a ComponentArray
    fixed_names = (:money, :intgov, :longcorp)
    fixed_array = ComponentArray(money=money, intgov=intgov, longcorp=longcorp)
    return ComponentArray(fixed_names=fixed_names, fixed_array=fixed_array)
end


function default_covmatrix()
    # The Multivariate normal and covariance matrix
    # 11 columns because it's got the bond returns in it
    # the 11 elements of the matrix, in order, are
    # US LogVol, US LogRet, Int'l LogVol, Int'l LogRet, Small LogVol, Small LogRet, Aggr LogVol, Aggr LogRet, Money Ret, IT Govt Ret, LTCorp Ret
    # so logvols are in indexes 1, 3, 5, 7 -- US, Int'l, Small, Aggr
    # and log rets are in 2, 4, 6, 8, 9, 10, 11 -- US, Int'l, Small, Aggr, Money, IT Govt, LT Corp
    covmatrix = [
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
    return covmatrix
end


function default_params(type="all")
    if type=="rates"
        return default_rates()
    elseif type=="equities"
        return default_equities()
    elseif type=="fixed"
        return default_fixed()
    elseif type=="covmatrix"
        return default_covmatrix()
    elseif type=="all"
        # TODO
        params = ComponentArray(            
        (rates=default_rates(),
        equities=default_equities(),
        fixed=default_fixed(),
        covmatrix=default_covmatrix())
        )
        return params
    end
end

end # end module