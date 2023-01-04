module structures

using Parameters 

mutable struct ir_params
    # interest-rate model parameters
    tau1::Real # Mean reversion point for the long term rate
    beta1::Real # Mean reversion strength for the logarithm of the long term rate
    theta::Real # Theta

    tau2::Real # Mean reversion point for the slope (defined as long rate - short rate)
    beta2::Real # Mean reversion strength for the slope
    sigma2::Real # Volatility of the slope
    tau3::Real # Mean reversion point for the volatility of the logarithm of the long rate
    beta3::Real # Mean reversion strength for the logarithm of the volatility of the logarithm of the long rate
    sigma3::Real # Volatility of the stochastic volatility process
    correl12::Real # Correlation of shocks to long rate and slope (long - short)
    correl13::Real # Correlation of shocks to long rate and volatility
    correl23::Real # Correlation of shocks to slope and volatility
    psi::Real # Psi
    phi::Real # Phi
    minr2::Real # Soft floor on the short rate
    unused::Real # Unused - maximum short rate
    minr1::Real # Soft floor on the long rate before random shock
    maxr1::Real # Soft cap on the long rate before random shock
    kappa::Real # Unused - When the short rate would be less than r2Min, it was set to Kappa times the long rate
    gamma::Real # Unused - do not change from zero
    initialvol::Real # Initial volatility of the long term rate    

    ir_params() = new()  # allows us to create an empty struct and fill it in as desired
end


function set_ir_defaults()
    # These are the default interest-rate parameters from the Academy's Interest Rate Generator (AIRG)
    # Version 7.1.202205 (released in May 2022). This economic scenario generator was released as the
    # Excel workbook 2022-academy-interest-rate-generator.xls. It was obtained by clicking through from
    # the link (https://www.soa.org/resources/tables-calcs-tools/research-scenario/).
    # The default interest-rate parameters can be found in the Parameters tab of the workbook.
    defaults = ir_params() # create an empty structure for the defaults
    defaults.tau1 = 0.0325
    defaults.beta1 = 0.00509
    defaults.theta = 1
    defaults.tau2 = 0.01
    defaults.beta2 = 0.02685
    defaults.sigma2 = 0.04148
    defaults.tau3 = 0.0287
    defaults.beta3 = 0.04001
    defaults.sigma3 = 0.11489
    defaults.correl12 = -0.19197
    defaults.correl13 = 0
    defaults.correl23 = 0
    defaults.psi = 0.25164
    defaults.phi = 0.0002
    defaults.minr2 = 0.0001
    defaults.unused = 0.4
    defaults.minr1 = 0.0115
    defaults.maxr1 = 0.18
    defaults.kappa = 0.25
    defaults.gamma = 0
    defaults.initialvol = 0.0287
    return(defaults)
end


end # module