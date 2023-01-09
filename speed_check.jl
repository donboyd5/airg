# speed_check
# check speed of file writing
# 

using Arrow
using CSV
using DataFrames
using DelimitedFiles
using FilePathsBase
using Parquet
using Parquet2
using Random
using RandomNumbers
using Tables

using Pkg

# Pkg.add("Arrow")
Pkg.add("Parquet2")

writedlm( "FileName.csv",  A, ',')

fdir = raw"E:\data\test"

fn_arw = fdir * "\\" * "f_arw.arrow"
fn_csv = fdir * "\\" * "f_csv.csv"
fn_parquet = fdir * "\\" * "f_parquet.parquet"
fn_wdlm = fdir * "\\" * "f_wdlm.csv"

n = 1000

mat = [
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

dump(Tables.table(mat))

# build a large data frame and see how fast that is

## Parquet2 ----




# write_parquet(fn_parquet, mat)
# write_parquet(fn_parquet, Tables.table(mat))

mat = rand(Float64, (14*10_000, 1200))
@time Arrow.write(fn_arw, Tables.table(mat))  # 14*10_000, 1200 matrix: 4.465416 seconds (168.68 M allocations: 3.791 GiB, 12.91% gc time, 5.88% compilation time)


mat = rand(Float64, (14, 1200))
# rnorm(Float64, (2, 3))

# write like Arrow.write(filename::String, tbl; file=false)
@time Arrow.write(fn_arw, Tables.table(mat), file=false) 
function f_arrow(n, mat=mat)
    # Write the matrix to the file
    @fastmath for i in 1:n
    # for i in 1:n
    Arrow.append(fn_arw, Tables.table(mat))
    end
end

@time f_arrow(10_000) 


function f_csv2(n, mat=mat)
io = open(fn_csv, "a")
    # Write the matrix to the file
    @fastmath for i in 1:n
    # for i in 1:n
        CSV.write(io,  Tables.table(mat), writeheader=false, append = true)
    end
    close(io)
end

@time f_csv2(10_000) # 12.6 seconds for 10000 writes of (14 x 1200) matrix
# Arrow.append(file::String, tbl)

function f_parquet(n, mat=mat)
    io = open(fn_csv, "a")
    # Write the matrix to the file
    @fastmath for i in 1:n
    # for i in 1:n        
        write_parquet(fn_parquet, Tables.table(mat))
    end
    close(io)
end

@time f_parquet(10)

# io = open("mytestfile.txt", "a")                                                                                                                                  
# IOStream(<file mytestfile.txt>)    
# @fastmath                                                                                                                                      

# julia> writedlm(io, test2)                                                                                                                                               
                                                                                                                                                                         
# julia> close(io)                              
function f_wdlm(n, mat=mat)
    mat = similar(mat)  # Preallocate mat
    io = open(fn_wdlm, "a")     
    @fastmath for i in 1:n
        # println(i)
        writedlm(io,  mat, ',')
    end
    close(io)
    return
end

@time f_wdlm(10_000)


## parquet second attempt ----
A = collect(reshape(1:120, 15, 8))
B = collect(reshape(121:200, 10, 8))

write_parquet(fn_parquet, Tables.table(A))
Parquet.ParFile(fn_parquet)

## hd5 ----
# using Pkg; Pkg.add("HDF5")
using HDF5

# Open an HDF5 file in append mode
fn_h5 = fdir * "\\" * "f_h5.h5"

h5 = h5open(fn_h5, "w")
dump(h5)



close(h5)

vec = [1, 2, 3]


A = collect(reshape(1:120, 15, 8))
B = collect(reshape(121:200, 10, 8))
h5write(fn_h5, "mygroup2/A", A)
h5write(fn_h5, "mygroup2/B", B)

data = h5read(fn_h5, "mygroup2/A", (2:3:15, 3:5))

h5read(fn_h5, "mygroup2/A", )
h5read(fn_h5, "mygroup2/B", )
close(fn_h5)


# djb
h5 = h5open(fn_h5, "w")
dump(h5)
A = collect(reshape(1:120, 15, 8))
write(h5, "A", A) 
dump(h5)
h5.id
h5.filename
B = collect(reshape(121:200, 10, 8))
write(h5, "B", B) 
dump(h5)
close(h5)

h5 = h5open(fn_h5, "r+")
h5read(h5, "A", (2:3:15, 3:5))
read(h5, "A")

close(h5)



h5write("/tmp/test2.h5", "mygroup2/A", A)
data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))


# # Create a dataset to store your data
# ds = h5create(h5, "my_dataset", (0,), maxdims=(Inf,), chunk=(10,), compression=:none)

# # Loop through your data
# for i in 1:n
#     # Create a row of data
#     row = ["column1_value", "column2_value", ...]
    
#     # Write the row to the dataset
#     push!(ds, row)
# end

# # Close the file
# close(h5)






## Parquet ----

pf = Parquet.File(fn_parquet, "a")

# Loop through your data
for i in 1:n
    # Create a row of data
    row = ["column1_value", "column2_value", ...]
    
    # Write the row to the file
    write(pf, row)
end


# n=10000 2.473632 seconds (2.63 M allocations: 544.598 MiB, 2.52% gc time)
# 0.376569 seconds (2.57 M allocations: 606.935 MiB, 13.99% gc time, 1.46% compilation time)

# open("mytestfile.txt", "a") do io
#     writedlm(io, test2)
#     end  

# function f_csv(n, mat=mat)
#     tmat = Tables.table(mat)
#     mat = similar(mat)  # Preallocate mat
    
#     io = open(fn_csv, "a")     
#     @fastmath for i in 1:n
#         # println(i)
#         tmat = Tables.table(mat)
#         CSV.write(io,  tmat, writeheader=false, append = true)
#     end
#     close(io)
#     return
# end

# function f_csv(n, mat=mat)
#     tmat = Tables.table(mat)
#     mat = similar(mat)  # Preallocate mat
    
#     io = open(fn_csv, "a")     
#     @fastmath for i in 1:n
#         # println(i)
#         tmat = Tables.table(mat)
#         CSV.write(io,  tmat, writeheader=false, append = true)
#     end
#     close(io)
#     return
# end

# @time f_csv(100)