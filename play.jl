

## component arrays

# https://github.com/jonniedie/ComponentArrays.jl
# https://discourse.julialang.org/t/componentarrays-vs-labelledarrays/67464/5
# https://juliahub.com/ui/Packages/ComponentArrays/cYHSD/0.13.5
# https://discourse.julialang.org/t/rfc-ann-componentarrays-jl-for-building-composable-models-without-a-modeling-language/38001


using ComponentArrays

c = (a=2, b=[1, 2]);

x = ComponentArray(a=5, b=[(a=20., b=0), (a=33., b=0), (a=44., b=3)], c=c)
# ComponentVector{Float64}(a = 5.0, b = [(a = 20.0, b = 0.0), (a = 33.0, b = 0.0), (a = 44.0, b = 3.0)], c = (a = 2.0, b = [1.0, 2.0]))

x.c.a = 400; x
# ComponentVector{Float64}(a = 5.0, b = [(a = 20.0, b = 0.0), (a = 33.0, b = 0.0), (a = 44.0, b = 3.0)], c = (a = 400.0, b = [1.0, 2.0]))

x[8]
# 400.0

collect(x)
# 10-element Array{Float64,1}:
#    5.0
#   20.0
#    0.0
#   33.0
#    0.0
#   44.0
#    3.0
#  400.0
#    1.0
#    2.0

typeof(similar(x, Int32)) === typeof(ComponentVector{Int32}(a=5, b=[(a=20., b=0), (a=33., b=0), (a=44., b=3)], c=c))

collect(1:2:13)

using ComponentArrays

ax = begin 
    Axis(
    (a = 1, 
    b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), 
    c = ViewAxis(8:10, (a = 1, b = 2:3))
    ))
 end
ax

A = [100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45]

ca = ComponentArray(A, ax)
# ComponentVector{Float64}(a = 100.0, b = [(a = 4.0, b = 1.3), (a = 1.0, b = 1.0), (a = 4.4, b = 0.4)], c = (a = 2.0, b = [1.0, 45.0]))

ca.a
# 100.0

ca.b
# 3-element LazyArray{ComponentVector{Float64,SubArray...}}:
#  ComponentVector{Float64,SubArray...}(a = 4.0, b = 1.3)
#  ComponentVector{Float64,SubArray...}(a = 1.0, b = 1.0)
#  ComponentVector{Float64,SubArray...}(a = 4.4, b = 0.4)

ca.c
# ComponentVector{Float64,SubArray...}(a = 2.0, b = [1.0, 45.0])

ca.c.b


using Pkg
Pkg.update()
Pkg.add("IJulia")
Pkg.build("IJulia")
using IJulia
notebook()
Pkg.add("Revise")

using Conda
Conda.add("jupyter-cache")
