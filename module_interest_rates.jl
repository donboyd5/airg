
module rates

using LabelledArrays
using Parameters 

mutable struct ir_params
    # interest-rate model parameters
    τ₁::Float64 # τ₁ tau1, Mean reversion point for the long term rate
    β₁::Float64 # beta1, Mean reversion strength for the logarithm of the long term rate
    θ::Float64 # theta, Theta

    τ₂::Float64 # tau2, Mean reversion point for the slope (defined as long rate - short rate)
    β₂::Float64 # beta2, Mean reversion strength for the slope
    σ₂::Float64 # sigma2, Volatility of the slope

    τ₃::Float64 # tau3, Mean reversion point for the volatility of the logarithm of the long rate
    β₃::Float64 # beta3, Mean reversion strength for the logarithm of the volatility of the logarithm of the long rate
    σ₃::Float64 # sigma3, Volatility of the stochastic volatility process

    ρ₁₂::Float64 # correl12, Correlation of shocks to long rate and slope (long - short)
    ρ₁₃::Float64 # correl13, Correlation of shocks to long rate and volatility
    ρ₂₃::Float64 # correl23, Correlation of shocks to slope and volatility

    ψ::Float64 # psi
    ϕ::Float64 # phi

    r₂_min::Float64 # minr2, Soft floor on the short rate
    r₂_max::Float64 # maxr2, unused - maximum short rate
    r₁_min::Float64 # minr1, Soft floor on the long rate before random shock
    r₁_max::Float64 # maxr1, Soft cap on the long rate before random shock
    κ::Float64 # κ, kappa, Unused - When the short rate would be less than r2Min, it was set to Kappa times the long rate
    γ::Float64 # γ, gamma, Unused - do not change from zero
    σ_init::Float64 # σ_init, initialvol, Initial volatility of the long term rate    
    maturities::Vector{Float64}

    ir_params() = new()  # allows us to create an empty struct and fill it in as desired
end


function set_ir_defaults()
    # These are the default interest-rate parameters from the Academy's Interest Rate Generator (AIRG)
    # Version 7.1.202205 (released in May 2022). This economic scenario generator was released as the
    # Excel workbook 2022-academy-interest-rate-generator.xls. It was obtained by clicking through from
    # the link (https://www.soa.org/resources/tables-calcs-tools/research-scenario/).
    # The default interest-rate parameters can be found in the Parameters tab of the workbook.
    defaults = ir_params() # create an empty structure for the defaults
    defaults.τ₁ = 0.0325
    defaults.β₁ = 0.00509
    defaults.θ = 1

    defaults.τ₂ = 0.01
    defaults.β₂ = 0.02685
    defaults.σ₂ = 0.04148

    defaults.τ₃ = 0.0287
    defaults.β₃ = 0.04001
    defaults.σ₃ = 0.11489

    defaults.ρ₁₂ = -0.19197
    defaults.ρ₁₃ = 0
    defaults.ρ₂₃ = 0

    defaults.ψ = 0.25164
    defaults.ϕ = 0.0002

    defaults.r₂_min = 0.0001
    defaults.r₂_max = 0.4
    defaults.r₁_min = 0.0115
    defaults.r₁_max = 0.18
    defaults.κ = 0.25
    defaults.γ = 0
    defaults.σ_init = 0.0287
    defaults.maturities = [0.25,0.5,1,2,3,5,7,10,20,30]
    return(defaults)
end

full_params(τ₁=0.035,vol=0.11489) = 
(
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

## now use labelled array to define parameters ----
ir_dims = (
    τ₁ = (1,:),   # Long term rate (LTR) mean reversion; djb: soa now uses .0325
    β₁ = (1,:), # Mean reversion strength for the log of the LTR
    θ = (1,:),
    
    τ₂ = (1,:),    # Mean reversion point for the slope
    β₂ = (1,:), # Mean reversion strength for the slope
    σ₂ = (1,:), # Volatitlity of the slope

    τ₃ = (1,:),  # mean reversion point for the vol of the log of LTR
    β₃ = (1,:), # mean reversion strength for the log of the vol of the log of LTR
    σ₃ = (1,:), # vol of the stochastic vol process

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
maturities = [0.25,0.5,1,2,3,5,7,10,20,30],) 
# lf1 = @LArray f1 adims



end # module