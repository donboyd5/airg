# speed_check
# check speed of file writing

## code formatting ----
# format Document command (Ctrl-Shift-I)
# Format Selection (Ctrl-K Ctrl-F) 


## duckdb ----
# https://www.christophenicault.com/post/large_dataframe_arrow_duckdb/
# https://duckdb.org/why_duckdb
# https://www.juliabloggers.com/welcome-to-duckdb/



## imports ----
using Arrow
using CSV
using DataFrames
using DelimitedFiles
using DuckDB
using FilePathsBase
using HDF5
import Parquet as p
using Parquet2
using Random
using RandomNumbers
using Tables

# using Pkg
# Pkg.add("Arrow")


## define filenames ----

fdir = raw"E:\data\test"

fn_arw = fdir * "\\" * "f_arw.arrow"
fn_csv = fdir * "\\" * "f_csv.csv"
fn_parquet = fdir * "\\" * "f_parquet.parquet"
fn_wdlm = fdir * "\\" * "f_wdlm.csv"


## define variables and matrices ----
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

## Arrow ----
# https://arrow.juliadata.org/stable/
# https://github.com/apache/arrow-julia
# With Arrow.write, you provide either an io::IO argument or a file_path to write the arrow data to, as well as a Tables.jl-compatible source that contains the data to be written.

Arrow.write(fn_arw, Tables.table(mat), file=false)

Arrow.append(fn_arw, Tables.table(mat * 3))

function f_arrow(n, mat=mat)
    # Write the matrix to the file
    for i in 1:n
     Arrow.append(fn_arw, Tables.table(mat * i))
    end
end


@time f_arrow(10_000)
# Arrow.close()

tmp = Arrow.Stream(fn_arw)



t2 = Arrow.Table(fn_arw)
dump(t2)
t2[1]

df = DataFrame(t2)



@time Arrow.write(fn_arw, Tables.table(mat), file=false) 
function f_arrow(n, mat=mat)
    # Write the matrix to the file
    @fastmath for i in 1:n
    # for i in 1:n
    Arrow.append(fn_arw, Tables.table(mat))
    end
end

## duckDB ----
db = DuckDB.open(":memory:")
con = DuckDB.connect(db)
res = DuckDB.execute(con,"CREATE TABLE integers(date DATE, jcol INTEGER);")
res = DuckDB.execute(con,"INSERT INTO integers VALUES ('2021-09-27', 4), ('2021-09-28', 6), ('2021-09-29', 8);")
res = DuckDB.execute(con, "SELECT * FROM integers;")
df = DuckDB.toDataFrame(res)

# or
df = DuckDB.toDataFrame(con, "SELECT * FROM integers;")
res = DuckDB.execute(con, "COPY (SELECT * FROM integers) TO 'test.parquet' (FORMAT 'parquet');")
res = DuckDB.execute(con, "SELECT * FROM 'test.parquet';")
DuckDB.appendDataFrame(df, con, "integers")
DuckDB.disconnect(con)
DuckDB.close(db)



## Parquet ----

pf = p.ParquetFile(fn_parquet, "a")
p.ParFile(fn_parquet)

tbl = Tables.table(mat)
p.write_parquet(fn_parquet, tbl)

for i in 1:3
    println("i = ", i)
    tbl = Tables.table(mat * 1)
    p.write_parquet(fn_parquet, tbl)
end





## Parquet2 ----
using Parquet2: writefile
tbl = Tables.table(mat)

io = IOBuffer()
writefile(io, tbl)  # write to IO buffer
close(io)

ds = Dataset() 

open(fn_parquet, write=true) do io
    fw = Parquet2.FileWriter(io)
    Parquet2.writeiterable!(io, tbl)  # write tables as separate row groups, finalization is done automatically
end



writefile(Vector{UInt8}, tbl)  # write to an array



## Parquet ----

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

## hd5 djb come back to this ----
# https://juliaio.github.io/HDF5.jl/stable/
# using Pkg; Pkg.add("HDF5")


# a "group" is analogous to a directory, a "dataset" is like a file.

# file creation modes
# "r"	read-only
# "r+"	read-write, preserving any existing contents
# "cw"	read-write, create file if not existing, preserve existing contents
# "w"	read-write, destroying any existing contents (if any)


# Open an HDF5 file in append mode
fn_h5 = fdir * "\\" * "f_h5.h5"

h5 = h5open(fn_h5, "w")
dump(h5)
close(h5)

# HDF5.name(h5)

A = collect(reshape(1:(14*1200), 14, 1200))

h5open(fn_h5, "w") do file
    HDF5.write(file, "1", mat * 2)  # alternatively, say "@write file A"
    HDF5.write(file, "2", mat * 3)  # alternatively, say "@write file A"
    # HDF5.write(file, "A", mat * 3)  # alternatively, say "@write file A"
end

h5read(fn_h5, "1",)
h5read(fn_h5, "2",)


# function f_hd5(n, mat=mat)
function f_hd5(n; mat=mat)
    mat = similar(mat)  # Preallocate mat
    h5open(fn_h5, "w") do file
        for i in 1:n
            HDF5.write(file, string(i), mat * i)
        end
    end
    return
end


mat = collect(reshape(1:(14*1200), 14, 1200))
@time f_hd5(4, mat=mat)

@time f_hd5(10_000, mat=mat)



h5read(fn_h5, "3",(1:5, 1:7))


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


## hd5 play ----
# https://notebook.community/albi3ro/M4/Numerics_Prog/HDF5 with syntax updates
test = fdir * "\\" * "test.h5"


fid=h5open(test,"w")
fid["string"]="Hello World"
close(fid)


fid=h5open(test,"r")
dump(fid)
println("names \n",fid.filename)
close(fid)


fid=h5open(test,"r")
dset=fid["string"]
println("the dataset: \t", typeof(dset))
data=read(dset)
println("the string: \t", typeof(data),"\t",data)
data2=read(fid,"string")
println("read another way: \t", typeof(data2),"\t",data2)
close(fid)

# use g_create to create two groups, one inside the other
fid=h5open(test,"w")
g = create_group(fid,"mygroup");
h = create_group(g,"mysubgroup");
println("\n path of h:  ",h.file)
close(fid)

# misc
fid=h5open(test,"w")
fid["data"]=randn(3,3);
attrs(fid["data"])["Temp"]="1";
attrs(fid["data"])["N Sites"]="100";
dump(fid)
close(fid)
fid=h5open(test,"r")
dset=fid["data"]
dump(fid)
println("typeof attrs: \t", typeof(attrs(dset)))
println("Temp: \t",attrs(dset)["Temp"])
println("N Sites: \t",attrs(dset)["N Sites"])
close(fid)

h5open(test, "w") do fid
    g = create_group(fid, "mygroup")
    dset = create_dataset(g, "myvector", Float64, (30,))
    write(dset,rand(10))
    # write(dset,rand(20))
end

fid["mygroup"] # error if file closed

fid=h5open(test,"r")
dump(fid)
fid["mygroup"]
fid["mygroup"]["myvector"]
g = fid["mygroup"]
dset = g["myvector"]
# equivalently 
dset = fid["mygroup/myvector"]
read(dset)
close(fid)

# start again
close(fid)
fid=h5open(test,"w")
g = create_group(fid, "mygroup")
dset = create_dataset(g, "mydataset", Float64, (30,10))
write(dset,rand(Float64, (30, 10)))
A = read(dset)
A = read(g, "mydataset")
Asub = dset[2:3, 1:3]
close(fid)

# It is also possible to write to subsets of an on-disk HDF5 dataset. This is useful to incrementally save to very 
# large datasets you don't want to keep in memory. For example,
fid=h5open(test,"w")
g = create_group(fid, "mygroup")
dset = create_dataset(g, "B", datatype(Float64), dataspace(1000,100,10), chunk=(100,100,1))
dset[:,1,1] = rand(1000)
# creates a Float64 dataset in the file or group g
close(fid)

fid=h5open(test,"r")
dset = fid["mygroup/B"]
dset[:,1,1]
close(fid)


# djb try loop
fid=h5open(test,"w")
g = create_group(fid, "A")
dset = create_dataset(g, "results", datatype(Float64), dataspace(10000,14,1200), chunk=(1,14,1200))
@time for i in 1:10000
    dset[i,:,:] = rand(14, 1200)
end
close(fid)


fid=h5open(test,"r")
dset = fid["A/results"]
dset[2,1:14,1:10]
close(fid)



## djb hd5 this works ----
function f_hd5(n; mat=mat)
    #mat = similar(mat)  # Preallocate mat
    fid=h5open(test,"w")
    g = create_group(fid, "A")
    dset = create_dataset(g, "results", datatype(Float64), dataspace(10000,14,1200), chunk=(1,14,1200))
    for i in 1:n
        dset[i,:,:] = mat * i
    end
    close(fid)
end

mat = collect(reshape(1:(14 * 1200), 14, 1200))

f_hd5(2)

@time f_hd5(10000) # 7 seconds vs 12 seconds for csv, not sure it's worth it

fid=h5open(test,"r")
dset = fid["A/results"]
dset[2000,1:14,1:10]
close(fid)




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