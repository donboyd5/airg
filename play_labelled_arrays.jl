
using ComponentArrays
using LabelledArrays

# we want a matrix p where:
#   each column is an equity fund
#   each row has a parameter
#   we can refer to a given parameter, such as a, for all funds
#   with the notation p.a
# we want it easily generalizable so that we can add another fund by adding a column to the matrix


## new attempt with component arrays ----
p1 = ComponentArray(a=0.1, b=0.2, c=0.3, d=5.)
p2 = ComponentArray(a=0.5, b=0.7, c=0.5, d=6.)
p3 = ComponentArray(a=0.2, b=0.9, c=0.2, d=7.)

a=nothing; b=nothing; c=nothing; d=nothing; e=nothing

(d, e)=p1 # bad, surprising result
d
e

(;d, e)=p1 # FAILS - using the semi-colon ensures that we can only unpack into properly named fields
(; a, b)=p1 # works
(; b, a)=p1 # works

a
b
p1.a
p1[2]

(a, b) = p1
a
b
c
(; a, b) = p
a

p123 = hcat(p1, p2, p3)


x = ComponentVector(a=1, b=2, c=3);
x2 = x .* x'
x2[1, :]
x2[2, :]
x2[3, :]

x2[:, 1]

y= ComponentVector(a=4, b=5, c=6)
xy = x .* y'
xy[1, :]
xy[:, 1]
xy[1, "a"]
xy[1, :a]
xy[:, :a]
(; a, b, c) = xy[1, :]
a, b, c


p123 = ComponentArray(a=p1, b=p2, c=p3)
# p123 = ComponentArray((a=p1, b=p2, c=p3)) # same thing - extra parentheses have no effect
p123.a
p123.b
p123[1]
p123[:a]
p123[:1]
p123[[1]]

p123[KeepIndex(1)]
p123[KeepIndex(1:4)]
@view p123[KeepIndex(1:4)]

(; a, b, c, d) = @view p123[KeepIndex(1:4)] # error
(; a, b, c, d) = p123[KeepIndex(1:4)] # error

## use axes djb this is it ----
#  allows us to use an index to get a fund, and unpack its parameters
a=nothing; b=nothing; c=nothing; d=nothing; e=nothing
px = Axis((a=1:4, b=5:8, c=9:12))
p123 = ComponentArray([p1, p2, p3], px)
p123[1] # gives the vector
p123[2]
p123[1].a
(; a, b, c) = p123[1]
d
a

ax = Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis(8:10, (a = 1, b = 2:3))));
A = [100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45];
ca = ComponentArray(A, ax)
ca.a
ca.b
size(ca.b)
ca.c
ca.c.b

# try to do this with both labelled arrays and component arrays

## data setup ----
f1 = [1.0, 2.0, 3.0] # fund 1 with parameters a, b, c
f2 = [4.0, 5.0, 6.0] # fund 2 with parameters a, b, c
f3 = [7.0, 8.0, 9.0] # fund 3 with parameters a, b, c
f4 = [10.0, 11.0, 12.0] # fund 3 with parameters a, b, c

fall = hcat(f1, f2, f3, f4)

## labelled arrays ----

adims = (a = (1,:), b = (2,:), c = (3,:)) # associate a row with each parameter

funddims = (bonds=(:, 1), st1=(:, 2), st2=(:, 3), st3=(:, 4))
bdims=merge(adims, funddims)

# construct a labelled array for each fund
lf1 = @LArray f1 adims
lf2 = @LArray f2 adims
lf3 = @LArray f3 adims
lf4 = @LArray f4 adims

lfall = @LArray (hcat(lf1, lf2, lf3, lf4)) bdims

lfall.a
lfall.b
lfall.c

lfall.bonds
lfall.st3
# lfall.a.bonds # can't do this
lfall[:, 1]

lfall[:, 1]
lfall[1, :]
lfall[:, 1].a


## now do it for component arrays ----
# https://jonniedie.github.io/ComponentArrays.jl/stable/api/
# ax = Axis((a = (1,:), b = (2,:), c = (3,:)))
adims = (a = (1,:), b = (2,:), c = (3,:)) # associate a row with each parameter
adims = (a = 1, b = 2, c = 3) #
ax = Axis(adims)
bdims = (bonds=(:, 1), st1=(:, 2), st2=(:, 3), st3=(:, 4))
bx = Axis(bdims)

cf1 = ComponentArray(f1, ax)
cf2 = ComponentArray(f2, ax)
cf3 = ComponentArray(f3, ax)
cf4 = ComponentArray(f4, ax)


cfall = ComponentArray(hcat(cf1, cf2, cf3, cf4), (ax, bx))
cfall.a
cfall[1]
cfall[1,:]
cfall[:]
cfall[:,1]
cfall[:,1].a

cfall = ComponentArray(hcat(cf1, cf2, cf3, cf4), (ax, ax))
cfall.a


ComponentArrays.labels(fall)
ComponentArrays.labels(cfall)


cfall = ComponentArray(hcat(cf1, cf2, cf3, cf4), ax)
cfall = ComponentMatrix(hcat(cf1, cf2, cf3, cf4), ax)

cfall = ComponentArray(hcat(cf1, cf2, cf3, cf4), cx2)

PartitionedAxis(2, (a = 1, b = 2))

PartitionedAxis((a = 1, b = 2))

cx2 = PartitionedAxis(1, (a = 1, b=2, c=3))


## old below here ----

ax = Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis(8:10, (a = 1, b = 2:3))))

A = [100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45]

ca = ComponentArray(A, ax)

ca
ca.a

ca.b
ca.b[3]
ca.b.b
ca.b.a

ca.c
ca.c.b

ca
collect(ca)

a = [1, 2, 3, 4]
b = [5, 10, 15, 20]
ab = hcat(a, b)  # 4 x 2
ab[:, 1]

cab = ComponentArray(ab=ab)
collect(cab)
cab[:, 1]



ax = Axis()
cab = ComponentArray(ab=ab)



lorenz_p = (σ=10.0, ρ=28.0, β=8/3)
lorenz_ic = ComponentArray(x=0.0, y=0.0, z=0.0)

lorenz_p.σ
lorenz_p.σ = 12.0 # error

lotka_p = (α=2/3, β=4/3, γ=1.0, δ=1.0)
lotka_ic = ComponentArray(x=1.0, y=1.0)
typeof(lotka_p)

comp_p = (lorenz=lorenz_p, lotka=lotka_p, c=0.01)
typeof(comp_p)
size(comp_p)
comp_p[1]
comp_p.lorenz

comp_ic = ComponentArray(lorenz=lorenz_ic, lotka=lotka_ic)
comp_ic[4]

t = (a = 1, b = 2.0, c = "3")
t.a


# bonds = (τ=, ϕ=, σ=)
bonds = (τ=0.5, ϕ=1.3, σ=0.7)
stocks = (τ=0.75, ϕ=1.7, σ=0.12)
vcat(bonds, stocks)
bs = (bonds=bonds, stocks=stocks)
bs.bonds
bs.bonds.τ
bs.stocks.τ
bs[1].τ
bs[2].τ

a = [1, 2, 3, 4]
b = [5, 10, 15, 20]
cat(a, b, dims =(2, 2))

hcat(a, b)
hcat(a, b)'
vcat(a, b)

foo = @LArray [1,2,3] (:a,:b,:c)
moo = @LArray [4,5,6] (:d,:e,:f)
vcat(foo, moo)


foo1 = @LArray [1,2,3] (:a,:b,:c)
foo2 = @LArray [4,5,6] (:a,:b,:c)
hcat(foo1, foo2)

@LArray hcat(f001, foo2)(a=(1,:), b=(2,:), c=(3,:))


ff = vcat(foo1, foo2)


# I want to concatenate the arrays so that each column is a fund and each row is a parameter (e.g., a, b, c)
# hcat will do that
ca1 = ComponentArray(a=1.0, b=2.0, c=3.0)
ca2 = ComponentArray(a=4.0, b=5.0, c=6.0)
hcat(ca1, ca2)
hcat(ca1, ca2)'
ComponentArray(hcat(ca1, ca2))
# Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis(8:10, (a = 1, b = 2:3))));
cax = Axis(a=(1,:), b=(2,:), c=(3,:))
a1 = [1.0, 2.0, 3.0]
a2 = [4.0, 5.0, 6.0]
hcat(a1, a2)
ComponentArray(hcat(a1, a2), cax)

ComponentArray(hcat(ca1, ca2), cax)



cax = 
ca12 = hcat(ca1, ca2)

vcat(ca1, ca2)


la1 = @LArray [1,2,3] (:a,:b,:c)
la2 = @LArray [4,5,6] (:a,:b,:c)
hcat(la1, la2)
# @LArray (hcat(la1, la2))
# @LArray (hcat(a1, a2))
la12 = @LArray (hcat(a1, a2)) (a = (1,:), b = (2,:), c = (3,:))
la12.a

lala12 = @LArray (hcat(la1, la2)) (a = (1,:), b = (2,:), c = (3,:))
lala12.a


