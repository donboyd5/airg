#=
TODO:
- finish fixed income data structures
- start loop through everything
- possibly pass months (integer) and randn array size months to each function
- for randn, this lets us control character of random numbers from OUTSIDE the function
    e.g., correlated or not

=#




## Credits ----
#= Credits

This Economic Scenario Generator (ESG) is largely based on the Academy Interest Rate
Generator (AIRG) jointly developed by the American Academy of Actuaries and the 
Society of Actuaries. A spreadsheet version of the model, and some documentation,
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

#= 
shift-alt-a toggles block comments (with symbols: pound equals at start, equals pound at end)
snv
fs
nrfg =#

## imports ----
using BenchmarkTools
using ComponentArrays
using Printf
using Random

# now my modules
# note that using is more conservative than import -- import brings everything in,
# using just brings names in -  you can't add methods to functions brought in by using
# you can't use "using as" but you can use "import as"

include("module_default_params.jl")
import .default_parameters as dp

include("module_interest_rates.jl")
import .intrates

include("module_equities.jl")
include("module_equities2.jl")
import .equities


## get default parameters ----
# CAUTION: use dot notation to change values, NOT indexing, which works on slices, not views, of the component array
x = dp.default_params()
# names(typeof(x))
dump(x)
getaxes(x)
x.rates
x.equities
x.fixed
x.covmatrix
x.covmat_axis

x.rates.τ₁
x.rates.τ₁ = .5
x.rates

x.equities.names
x.equities.names[1]
x.equities.names[1] = :don # error
x.equities.funds
x.equities.funds[:usstocks]
x.equities.funds[:usstocks].τ
x.equities.funds[:usstocks].τ = 7 # does not change the value in x.equities.funds.usstocks because we had a slice not a view!
x.equities.funds.usstocks.τ=7  # dot notation DOES change the value
x.equities.funds[:usstocks]
x.equities.funds

x.fixed.names
x.fixed.names[1]
x.fixed.funds
x.fixed.funds[:money]
x.fixed.funds[:money].m
x.fixed.funds[:money].m=7  # does NOT change the value
x.fixed.funds.money.m=7  # DOES change the value
x.fixed.funds.money

x.rates.τ₁
x.rates.rate_floor

x.equities
x.equities.names
x.equities.array.usstocks
x.equities.array[:intlstocks]
# x.equities.array[1] # does not get the vector of assets

x.covmatrix # gets a view
x.covmatrix[1,1] = 6
x.covmatrix

(; τ₁, β₁, θ,
        τ₂, β₂, σ₂,
        τ₃, β₃, σ₃,
        ρ₁₂, ρ₁₃, ρ₂₃,
        ψ, ϕ, r₂_min, r₂_max, r₁_min, r₁_max,
        κ, γ, σ_init, rate_floor, maturities) = x.rates
ϕ
maturities


## get yield curves ----
stcurve = [0.01, 0.02, 0.024, 0.03, 0.04, 0.05, 0.055, 0.06, 0.07, 0.08] # starting yield curve
intrates.scenario(stcurve, x.rates)
intrates.scenario(stcurve, x.rates, months=24)


## equities ----
x.covmatrix
equities.loop2(x; sims=10, months=12)

@time equities.loop2(x; sims=10_000, months=1200)
#  3.259979 seconds (12.00 M allocations: 183.107 MiB)
# 108.290993 seconds (828.00 M allocations: 18.060 GiB, 2.38% gc time) unpacking tuple approach
# 16.329537 seconds (156.00 M allocations: 8.047 GiB, 4.81% gc time) passing subarray to slv function
# 26.730455 seconds (492.00 M allocations: 13.053 GiB, 4.74% gc time)  @ unpack array elements


@time equities.loop2(x; sims=2000, months=600)


# scenario(params,covmatrix;months=1200)
# (;σ_v,σ_0, ρ,A,B,C) = params
equities.scenario(x.equities, x.covmatrix)

@btime equities.loop(x.equities) # r6.401 ms (522 allocations: 30.12 KiB) 1.520 ms (86 allocations: 2.88 KiB) 787.700 μs (69 allocations: 2.20 KiB)
@btime equities.loop2(x.equities) # 6.385 ms (518 allocations: 31.44 KiB)  1.492 ms (82 allocations: 2.44 KiB)800.100 μs (65 allocations: 1.77 KiB)

equities.loop(x.equities)

# 812.900 μs (124 allocations: 3.05 KiB) no preallocation
# 811.800 μs (142 allocations: 3.47 KiB) prealloc
# 7.300 μs (70 allocations: 1.70 KiB)


#  895.000 ms (48000070 allocations: 732.42 MiB)
# 861.622 ms (48000070 allocations: 732.42 MiB)

using Distributions
covmatrix=x.covmatrix
convert(covmatrix, Float64)

dp.default_covmatrix()

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

Z = MvNormal(
	# define random numbers we will get
	# we will need 11 sets of correlated random numbers, one per column of the covariance (correlation) matrix, which includes not just correlations
	# of returns, but also of volatilities
    zeros(11), # means for return and volatility
    covmatrix # covariance matrix
    # full covariance matrix in AAA Excel workook on Parameters tab
    )	


## OLD BELOW HERE ----

vals = x.equities.array
for fund in x.equities.names
    println(fund)
    println(vals[fund])
    @printf "tau = %0.3f\n" vals[fund].τ
    @printf "rho = %0.3f\n" vals[fund].ρ
end


vals = x.fixed.array
for fund in x.fixed.names
    println(fund)
    println(vals[fund])
    @printf "kappa = %0.4f\n" vals[fund].κ
    # @printf "rho = %0.3f\n" vals[fund].ρ
end



xe = dp.default_equities()
xe


dp.default_params("rates")
dp.default_params("equities")
dp.default_params("fixed")
dp.default_params("covmatrix")
dp.default_params("all")
dp.default_params()

x = dp.default_params()
x = dp.default_params("all")
dump(x)
size(x)
x.rates
x.rates.τ₁
x.equities
x.equities.equity_names
x.equities.equity_array
x.equities[1]
x.equities[2] # not what I expected -- this is just going through each element of equities
x.equities[3] # not what I expected
x.equities.equity_array
x.equities.equity_array.usstocks
x.equities.equity_array.usstocks.τ
x.equities.equity_names[1]

# so to index through equity funds, we do:
x.equities.equity_array[x.equities.equity_names[1]] # and 2 and so on
fnames = x.equities.equity_names
farray = x.equities.equity_array
(; τ, ϕ) = farray[fnames[1]]
τ
ϕ

x.fixed.fixed_names
x[1]
x[2]

x.covmatrix


xx = dp.default_params("equities")
dump(xx)
xx.equity_names
xx.equity_array
xx[1]
xx[2]
xx.equity_array.usstocks
xx.equity_array.intrisk
xx.equity_array[1] # not what I expected
xx.equity_array[:usstocks]

x=dp.default_params("equities")
x.equity_names
x.equity_funds
x.equity_funds.usstocks
x.equity_funds[:usstocks]
x.equity_funds[1]

fnames, farray = dp.default_params("equities")
fnames
farray
farray[1]

default_parameters

include("module_interest_rates.jl")
using .rates # when we update the file, we don't need to rerun the using line, just the include line

include("module_fixed_income.jl")
import .fixed_income as fi

include("module_equities.jl")
using .equities
# import .structures as st

## interest rates ----
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


## fixed income ----
## djb this next

## equities OLD ----
equities.funds
equities.funds.usstocks
equities.funds.usstocks.τ
equities.funds.aggr.τ

equities.fundnames
for fund in equities.fundnames
    println(fund)
    println(equities.funds[fund])
    println(equities.funds[fund].ρ)
end

equities.cov_matrix




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

Z = MvNormal(
	# define random numbers we will get
	# we will need 11 sets of correlated random numbers, one per column of the covariance (correlation) matrix, which includes not just correlations
	# of returns, but also of volatilities
    zeros(11), # means for return and volatility
    x.covmatrix # covariance matrix
    # full covariance matrix in AAA Excel workook on Parameters tab
)

rand(Z) 
rand(Z, 5)

djb = rand(Z, 10000)
djb[:, [1, 3]]

months = 1200
sims = 10000
djb = rand(Z, (sims, months))
@time rand(Z, (sims, months)) # 4.5 secs

f = function(covmatrix, sims, months)
    Z = MvNormal(
        zeros(11), # means for return and volatility
        covmatrix
        )
    zx = rand(Z)
    for i in 1:sims
        for j in 1:months
            rand!(Z,zx)
        end # j
    end # i
end # function

f(x.covmatrix, 10, 10)
@time f(x.covmatrix, sims, months) # 3.354763 seconds (12.00 M allocations: 183.107 MiB)



size(djb)
typeof(djb)
djb[:, :]
djb[1, :] # sim 1, all months, the vec for each month
djb[:, 1] # all sims, month 1, the vec for each sim
djb[7, 3] # the vec for sim 7, month 3
djb[7, 3][1] # first element of the 11-element vec


djb[1, 1]
djb[1, 1][1]

a=10
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


## selected julia notes ----

# using UpdateJulia
# update_julia()

# https://quant.stackexchange.com/questions/1260/r-code-for-ornstein-uhlenbeck-process
# Take a look at the sde package; specifically the dcOU and dsOU functions. You may also find some examples 
# on the R-SIG-Finance mailing list, which would be in the results of a search on www.rseek.org

# to get a greek letter type \ then a short name, such as \pi then select from list or hit enter etc.

# https://www.julia-vscode.org/docs/stable/userguide/runningcode/
# code cells start with ## 
# Execute Code Cell in REPL: Alt+Enter

## setting up an environment
# https://pkgdocs.julialang.org/v1/environments/
# https://jkrumbiegel.com/pages/2022-08-26-pkg-introduction/
# https://www.julia-vscode.org/docs/stable/userguide/env/
# get into pkg from the julia repl ]
# activate .
# st   # gives status
# st -m # status of manifest
# add DataFrames
# st
#  # repeat

## miscellaneous commands and notes
# cls in terminal to clear its console
# ctrl-l or clear in julia repl to clear its console

#### links for component arrays and for other help ----
#=
Component arrays
# https://jonniedie.github.io/ComponentArrays.jl/stable/api/

=#


cm2 = ComponentArray(mat=[
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
])

zx
ComponentArray(zx)
# ax = Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis(8:10, (a = 1, b = 2:3))));
ax = Axis((logvol=Viewaxis([1, 3, 5, 7], (a=1, b=2, c=3, d=4))))

ax = Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis(8:10, (a = 1, b = 2:3))))

ax = Axis((a = 1))
ax = Axis((b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2)))))
ax = Axis((c = ViewAxis(8:10, (a = 1, b = 2:3))))
ax = Axis((c = ViewAxis((8, 9, 10), (a = 1, b = 2:3))))

ax = Axis((c = ViewAxis((8, 9, 11), (a = 1, b = 2:3))))

ComponentArray((zx, axes=ax))

ca = ComponentArray(zx, ax)
ca.c

ax = Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis(8:10, (a = 1, b = 2:3))));
ax = Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis((8, 10), (a = 1, b = 2))))
A = [100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45];
ca = ComponentArray(A, ax)
ca.a
ca.b
ca.b.a
ca.c

ax=Axis((a=ViewAxis9))

ax= Axis((a=1, b=2, c=3, d=4,e=5,f=6,g=7,h=8,i=9,j=10,k=11))
ax= Axis((a=1, b=2, c=3, d=4,e=5))
ab=ComponentArray(A,ax)
ab.e

x.equities.names
tuple(Symbol(string(x) * "_vol") for x in x.equities.names)


t = (:a, :b, :c)
suffix = "_suffix"
Tuple([Symbol(string(xx) * suffix) for xx in t])

typeof(a)
new_t = tuple(Symbol(string(x) * suffix) for x in t)

x.fixed.names
# usstocks, :intlstocks, :intrisk, :aggr
ax=Axis(usstocks_vol=1, usstocks=2, 
    intlstocks_vol=3, intlstocks=4, 
    intrisk_vol=5, intrisk=6, 
    aggr_vol=7, aggr=8,
    money=9, intgov=10, longcorp=11)
zx
cazx=ComponentArray(zx, ax)
cazx.usstocks
cazx.usstocks_vol

s1 = :intlstocks
s2=Symbol(string(s1) * "_vol")
cazx[s2]



cmat = [1.0 .2 .3;
        .2 1.0  .4;
        .3 .4 1.0]

zb = MvNormal(
    zeros(3), # means for return and volatility
    cmat # covariance matrix
    # full covariance matrix in AAA Excel workook on Parameters tab
)




function f2(yy)
    ComponentArray(rand(yy), Axis((a=1, b=2, c=3)))
end

a = f2(zb)

a.b
a[:b]

@btime a.b
@btime a[:b]

@btime f2(zb)
@btime rand(zb)

# how to write an in-place function
Zₜ = rand!(Z, Zₜ)

function f3(ca, zb)
    ca = ComponentArray(rand!(zb, ca), Axis((a=1, b=2, c=3)))
    nothing
end

# preallocate then update
ca = ComponentArray(rand(zb), Axis((a=1, b=2, c=3))) # preallocate
ca =rand!(zb, ca)
ca.a



# US LogVol
# US LogRet
# Int'l LogVol
# Int'l LogRet
# Small LogVol
# Small LogRet
# Aggr LogVol
# Aggr LogRet
# Money Ret
# IT Govt Ret
# LTCorp Ret


