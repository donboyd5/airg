module fixed_income

# inspired by code by Alec Loudenback, here: https://github.com/JuliaActuary/Learn/blob/master/AAA_Equity_Generator.jl
# Reference: [https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf](https://www.actuary.org/sites/default/files/pdf/life/c3supp_march05.pdf)"

# documentation on ComponentArrays
# https://jonniedie.github.io/ComponentArrays.jl/stable/api/
# other useful sources
# https://www.matecdev.com/


# How the fixed income fund Visual Basic code works in the AIRG spreadsheet model version 7.1.202205
#
# function ProcessAllScenarios in module NewGenerator
#   loops through 10000 (generally) simulations, and in each simulation
#   calls fundScenario.Generate in class module FundScenarioClass
#     which loops through 1200 months (100 years) for the current simulation
#     and in each month, after calling the getNextReturn function for each equity class, 
#     calls the getNextReturn function for each fixed income fund class
#     (which is in the class module FixedFundReturnClass):
#       MoneyFund.getNextReturn(priorCurve, currentCurve, randNum(k, 8))
#       IntGovtFund.getNextReturn(priorCurve, currentCurve, randNum(k, 9))
#       LongCorpFund.getNextReturn(priorCurve, currentCurve, randNum(k, 10))

# The following variables appear to be available as global (?) values to the getNextReturn function (verify):
    # Public maturity As Double       'maturity in years for bonds in this fund
    # Public monthlyFactor As Double  'usually 1/12 = 0.0833333
    # Public monthlySpread As Double
    # Public duration As Double       'measured in years
    # Public volatility As Double     'volatility due to credit spreads

# Here is the relevant Visual Basic code in the getNextReturn function    
    # prevIntRate = prevYldCurve.rateAtMaturity(maturity)
    # currIntRate = currYldCurve.rateAtMaturity(maturity)
    # currReturn = monthlyFactor * (prevIntRate + monthlySpread) + duration * (prevIntRate - currIntRate) + shock * (prevIntRate ^ 0.5) * volatility
    # getNextReturn = currReturn


# Default parameters for bond index returns from the Parameters sheet of the AIRG spreadsheet model 
						
#        	Money   	US Intermed	US Long			
# Symbol	Market	    Govt    	Corporate   Description		
# m         0.25	    7	        10	        Reference maturity on the treasury curve (years)		
# Beta0	    0.08333	    0.08333	    0.08333	    Monthly / annual		
# Kappa	    -0.445%	    -0.153%	    0.704%	    Mean spread over treasury of reference maturity 		
# Beta1	    -0.07148	3.65043	    5.81293	    Effective duration in years		
# Sigma	    0.0037  	0.05239	    0.08282	    Random volatility, largely due to credit spread changes		


using ComponentArrays

# set up default parameter values for fixed income funds

# as named tuples
money = (m=0.25, β₀=0.08333, κ=-0.00445, β₁=-0.07148, σ=0.0037)
intgov = (m=7, β₀=0.08333, κ=-0.00153, β₁=3.65043, σ=0.05239)
longcorp = (m=10, β₀=0.08333, κ=0.00704, β₁=5.81293, σ=0.08282)

# combine the above into a named tuple, and put it into a ComponentArray
fixed = ComponentArray((money=money, intgov=intgov, longcorp=longcorp))
fundnames = (:money, :intgov, :longcorp) 

fixed.money

(; m, β₀, κ, β₁, σ) = fixed[:intgov]

function f(var, ca)
    return (; m, β₀, κ, β₁, σ) = ca[var]    
end

f(:intgov, fixed)
f(:longcorp, fixed)

for fund in fundnames
    println(f(fund, fixed))
end


end # module


# misc notes below here

# example of how to construct a complex component array that can be indexed with a number
# a=nothing; b=nothing; c=nothing; d=nothing; e=nothing
# px = Axis((a=1:4, b=5:8, c=9:12))
# p1 = ComponentArray(a=0.1, b=0.2, c=0.3, d=5.)
# p2 = ComponentArray(a=0.5, b=0.7, c=0.5, d=6.)
# p3 = ComponentArray(a=0.2, b=0.9, c=0.2, d=7.)
# p123 = ComponentArray([p1, p2, p3], px)
# p123[1] # gives the vector
# p123[2]
# p123[1].a
# (; a, b, c) = p123[1]
# d
# a


# as component arrays
# money = ComponentArray(m=0.25, β₀=0.08333, κ=-0.00445, β₁=-0.07148, σ=0.0037)
# intgov = ComponentArray(m=7, β₀=0.08333, κ=-0.00153, β₁=3.65043, σ=0.05239)
# longcorp = ComponentArray(m=10, β₀=0.08333, κ=0.00704, β₁=5.81293, σ=0.08282)

# c = ViewAxis(8:10, (a = 1, b = 2:3))
# ax = Axis((money=1:5, intgov=6:10, longcorp=11:15))
# ax = Axis(money=ViewAxis((1, 4, 7, 11, 14)))
# fixed = ComponentArray([money, intgov, longcorp], ax)
# fixed = ComponentArray([money, intgov, longcorp]) # this works if they are component arrays, but not if named tuples
# fixed.money
# fixed[1].m
# fixed[2].κ
# fixed[3].β₁
# fixed[3].σ

# fixed[vars[1]].m
# fixed[vars[2]].κ
# fixed[vars[3]].β₁
# fixed[vars[1]].σ


# how to unpack
# (; m, β₀, κ, β₁, σ) = fixed[2]
# β₁

# the following could work if we can figure out how to keep the labels
# fixed = ComponentArray(vcat(money, intgov, longcorp), ax)
# fixed.money