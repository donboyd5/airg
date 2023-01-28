#= Credits

This Economic Scenario Generator (ESG) is largely based on the Academy Interest Rate
Generator (AIRG) jointly developed by the American Academy of Actuaries and the 
Society of Actuary. A spreadsheet version of the model, and some documentation,
can be found here:
    https://www.actuary.org/content/economic-scenario-generators

Most of the relevant documentation for the AIRG can be found at:
    https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf
    https://www.actuary.org/sites/default/files/pdf/life/c3_june05.pdf
    https://www.actuary.org/sites/default/files/files/C3_Phase_I_Report_October_1999.pdf

I drew many of the methods from the AIRG spreadsheet model and associated
Visual Basic code. Unless noted elsewhere, we reviewed the code in 
Version 7.1.2205, released in mid-2022.

Much of the code for interest rates and equity funds is based heavily on
code by Alec Loudenback at:
  https://github.com/JuliaActuary/Learn/blob/master/AAA_ESG.jl  interest rates
  https://github.com/JuliaActuary/Learn/blob/master/AAA_Equity_Generator.jl equities


  At the time I obtained the code from the Learn repository, it had an MIT license:
    MIT License

    Copyright (c) 2020 JuliaActuary

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

=#



## imports ----
using ComponentArrays


# now my modules
# note that using is more conservative than import -- import brings everything in,
# using just brings names in -  you can't add methods to functions brought in by using

include("module_interest_rates.jl")
using .rates # when we update the file, we don't need to rerun the using line, just the include line

include("module_fixed_income.jl")
import .fixed_income as fi

include("module_equities.jl")
using .equities
# import .structures as st

# get interest rate parameters as component vector for fast indexing by name (?)
rates.default
rates.default.τ₁
rates.default.maturities

(; τ₁, maturities) = rates.default

stcurve = [0.01, 0.02, 0.024, 0.03, 0.04, 0.05, 0.055, 0.06, 0.07, 0.08] # 10-element vector of rates
rparms = rates.default
rparms.τ₁ = .06
rparms

rates.default.τ₁
rparms.τ₁

rates.scenario(stcurve, rates.default)
rates.scenario(stcurve, rparms)

# djb - next: in module_interest_rates, loop through months


## test parameters ----
pdjb = rates.set_ir_defaults() # my struct approach (?)
pal = rates.full_params() # Alec's approach to interest-rate parameters

dump(pdjb)
dump(pal)

pdjb.τ₁
pal.τ₁

fi.fixed
fi.f(:intgov, fi.fixed)

abspath(PROGRAM_FILE)
@__FILE__

# pdjb.τ₁ = .035

pdjb.ϕ
pal.ϕ

pdjb.ρ₁₂
pal.ρ₁₂

pdjb.maturities
pal.maturities

pdjb.τ₁
pal.τ₁

pdjb.τ₁
pal.τ₁

a = ComponentArray(f=(1.0, 3))

# greek letters -- tab completion (or carriage return)
# type \tau and then TAB (the tab key) for τ
# to get a subscript, type \tauTAB\_1TAB to get τ₁


# interest-rate parameters
# τ₁ = τ₁,   # Long term rate (LTR) mean reversion; djb: soa now uses .0325
# β₁ = 0.00509, # Mean reversion strength for the log of the LTR
# θ = 1,
# τ₂ = 0.01,    # Mean reversion point for the slope
# β₂ = 0.02685, # Mean reversion strength for the slope
# σ₂ = 0.04148, # Volatitlity of the slope
# τ₃ = 0.0287,  # mean reversion point for the vol of the log of LTR
# β₃ = 0.04001, # mean reversion strength for the log of the vol of the log of LTR
# σ₃ = vol, # vol of the stochastic vol process
# ρ₁₂ = -0.19197, # correlation of shocks to LTR and slope (long - short)
# ρ₁₃ = 0.0,  # correlation of shocks to long rate and volatility
# ρ₂₃ = 0.0,  # correlation of shocks to slope and volatility
# ψ = 0.25164,
# ϕ = 0.0002,
# r₂_min = 0.01, # soft floor on the short rate
# r₂_max = 0.4, # unused - maximum short rate
# r₁_min = 0.015, # soft floor on long rate before random shock; djb soa uses .0115
# r₁_max = 0.18, # soft cap on long rate before random shock
# κ = 0.25, # unused - when the short rate would be less than r₂_min it was κ * long 
# γ = 0.0, # unused - don't change from zero
# σ_init = 0.0287,
# months = 12 * 30,  # djb - make number of years a parameter so that it can be matched with # of years for equities
# rate_floor = 0.0001, # absolute rate floor
# maturities = [0.25,0.5,1,2,3,5,7,10,20,30],

# equity parameters
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