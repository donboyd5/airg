
using Distributions


# Run the simulations
nsims = 100
nyears = 10
results = []

for i in 1:nsims
    for y in 1:nyears
        
end




for i in 1:num_simulations
    investment_returns = rand(investment_return_distribution, years_to_retirement)
    final_account_balance = cumprod(1 + investment_returns) * pension_benefit
    push!(results, final_account_balance[end])
end





# Define benefit payout function
function benefit_payout(salary::Float64, years_of_service::Float64)
    return salary * years_of_service * 0.01
end

# Define employer contribution function
function employer_contribution(salary::Float64, years_of_service::Float64)
    return salary * years_of_service * 0.005
end

# Define investment return function
function investment_return(mean::Float64, std_dev::Float64)
    return rand(Normal(mean, std_dev))
end

# Define solvency function
function solvency(benefit_obligations::Float64, assets::Float64)
    return assets >= benefit_obligations
end

# Define scenario function
function scenario(mean::Float64, std_dev::Float64, n::Int64)
    benefit_obligations = 0.0
    assets = 0.0
    for i in 1:n
        salary = 50000.0
        years_of_service = 10.0
        benefit_obligations += benefit_payout(salary, years_of_service)
        assets += employer_contribution(salary, years_of_service) + investment_return(mean, std_dev)
    end
    return solvency(benefit_obligations, assets)
end

# Run scenario with different investment returns
scenario(0.05, 0.1, 100) # 5% mean return and 10% standard deviation
scenario(0.03, 0.1, 100) # 3% mean return and 10% standard deviation
