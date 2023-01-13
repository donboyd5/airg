# https://web.eecs.umich.edu/~fessler/course/551/julia/tutor/03-diag.html
# memory and speed


## imports ----
using Distributions
using LinearAlgebra
using Statistics


## parameters and constants ----
# Define the parameters for the multivariate lognormal distribution
mean = [0.1, 0.05] # mean returns for stocks and bonds
cov = [0.01 0.003; 0.003 0.005] # covariance matrix for returns of stocks and bonds

# Define the number of time steps and initialize arrays to store the returns
T = 10000000
returns_stocks = Array{Float64}(undef, T)
returns_bonds = Array{Float64}(undef, T)

# Generate the time series of returns
mvn = MvNormal(mean, cov)
for t in 1:T
    returns = rand(mvn)
    returns_stocks[t] = returns[1]
    returns_bonds[t] = returns[2]
end

correlation = cor(returns_stocks, returns_bonds)
cov[1, 2] / (sigma[1, 1] * sigma[2, 2]) # expected correlation

# Statistics.cov(returns_stocks, returns_bonds)
Statistics.cov(hcat(returns_stocks, returns_bonds))


