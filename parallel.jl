# https://vsert.com/posts/vectorization/

using BenchmarkTools
import Random
using Base.Threads
using Distributed
using ThreadsX


## Expression ----
# sin(x)^2 + cos(x)^2

## Scalar function ----
function ftx(x)
    return sin(x)^2 + cos(x)^2
end

## Imperative reduction in place ----
function fx(X)
    r = 0.0
    for x in X
        r = r +( sin(x)^2 + cos(x)^2)
    end
    return r
end

## Custom threaded function in place ----
# Custom threaded function using first element of a column to save the result (so threadsafe iirc). Using column major slicing for speed

function sr!(X)
    @threads for i in 1:size(X, 2)
        @inbounds X[1,i] = sum(sin.(X[:,i]) .^2 .+ cos.(X[:,i]) .^2)
    end
    return sum(X[1,:])
end

## test ----
Random.seed!(42)
N = 1024 # timings below done with this
N = 10000
X = rand(N, N)


## @code_native shows a lot of calls to mapreduce, so JIT is converting this

@btime Y = sum(sin.(X).^2 .+ cos.(X).^2) # 9.178 ms (19 allocations: 8.00 MiB)

# Vectorize function call
@btime sum(ftx.(X)) # 8.776 ms (6 allocations: 8.00 MiB)

# Map reduce (functional programming)#
@btime mapreduce(x->sin(x)^2+cos(x)^2,+, X); # 7.730 ms (1 allocation: 16 bytes)
# This leads to an allocation of 16 bytes, 2 64 bit floats, so very little memory overhead
    
# Imperative loop -- this looks pretty good to me  - djb
@btime fx(X) # 7.701 ms (1 allocation: 16 bytes)
# Leads also to 16 bytes allocation, Julia allocates 2 floats, no more.
    
# Threaded loop modify in place#
Y = copy(X)
@btime sr!(Y) # 9.982 ms (3080 allocations: 24.38 MiB)

#  Distributed
#  The previous example is parallel using threads, let’s use the distributed model.
@btime @distributed (+) for x in X
    sin(x)^2 + cos(x)^2
    end # 8.964 ms (19 allocations: 8.00 MiB)

# ThreadsX
# This is a specialized package, and very fast, though not as lean in memory use.
    
@btime ThreadsX.mapreduce(x -> sin(x)^2 + cos(x)^2, +, X) # 7.634 ms (53 allocations: 4.77 KiB)

# The key advantage here is that you can use the standard functional programming code, so almost no code changes.

