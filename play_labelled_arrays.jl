
using ComponentArrays
using LabelledArrays

# we want a matrix p where:
#   each column is an equity fund
#   each row has a parameter
#   we can refer to a given parameter, such as a, for all funds
#   with the notation p.a
# we want it easily generalizable so that we can add another fund by adding a column to the matrix

# try to do this with both labelled arrays and component arrays

## data setup ----
f1 = [1.0, 2.0, 3.0] # fund 1 with parameters a, b, c
f2 = [4.0, 5.0, 6.0] # fund 2 with parameters a, b, c
f3 = [7.0, 8.0, 9.0] # fund 3 with parameters a, b, c
f4 = [10.0, 11.0, 12.0] # fund 3 with parameters a, b, c

fall = hcat(f1, f2, f3, f4)

## labelled arrays ----

adims = (a = (1,:), b = (2,:), c = (3,:)) # associate a row with each parameter

# construct a labelled array for each fund
lf1 = @LArray f1 adims
lf2 = @LArray f2 adims
lf3 = @LArray f3 adims
lf4 = @LArray f4 adims

lfall = @LArray (hcat(lf1, lf2, lf3, lf4)) adims

lfall.a
lfall.b
lfall.c

## now do it for component arrays ----





## old below here ----
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


