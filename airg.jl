
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


## loads 
using Accessors
using DataFrames
# using ExcelReaders
using Missings
using NamedArrays
# using NamedTuples - not needed
using Parameters  # allows key word arguments to struct, using @with_kw
using Pkg
using Unicode
using XLSX

# packages to consider:
#   AxisArrays
#   ExcelReaders

# now my modules
include("module_structures.jl")
using .structures
# import .structures as st


# Pkg.add("Accessors")
# import Pkg; Pkg.precompile()

## techniques ----

# accessing and setting struct fields by name -- string
# z["tau1"]  ERROR
# getproperty(z, "tau1") ERROR
getproperty(z, Symbol("tau1"))
getfield(z, Symbol("tau1"))
z
setproperty!(z, Symbol("tau1"), 7.0)
z
z.tau1

## END techniques

## get defaults

ir_defaults = structures.set_ir_defaults()
ir_defaults.maxr1
ir_defaults

ir_defaults = Nothing




## read from Excel
# file_name = raw"E:\R_projects\SOA_Model_Risk\airg\data\2022-academy-interest-rate-generator.xls"
# 2022-academy-interest-rate-generator_converted_to_xlsx.xlsx
file_name = raw"E:\R_projects\SOA_Model_Risk\airg\data\2022-academy-interest-rate-generator_converted_to_xlsx.xlsx"
wb = XLSX.readxlsx(file_name)
XLSX.sheetnames(wb)
psh = wb["Parameters"]

# Parameters 
# interest rate generator "a2:f25"
df = DataFrame(psh["A2:F25"], :auto)
df = DataFrame(XLSX.readtable(file_name, "Parameters"))
ir_gen_mat = psh["A2:F25"] # matrix any
ir_gen_mat[1,:]
ir_gen_mat[3:end, 2] # range name

# create a data frame that only has rows with nonmissing values for x1
A = DataFrame(ir_gen_mat[3:end, [2, 3, 4, 6]], ["var", "used", "default", "description"])

# one way to clean the data
function f(df)
    df = dropmissing(df, :var)
    df.var = lowercase.(df.var)
    for (name) in ["used", "default"] #  eachcol(df)
        df[!, name] = convert.(Float64, df[!, name])
    end
    return df
end

A = f(A)
A













function getval(name::String)
    # this is fast
    field = Symbol(name)
    code = quote
        (obj) -> obj.$field
    end
    return eval(code)
end
const doSomething2 = getval("a")

doSomething2($z)


setproperty!(z, field, "world")

z = djb(tau1=Nothing, beta1=Nothing, theta=Nothing)

djb.tau1=8
@set djb.tau1=8

@with_kw mutable struct params_struct
    tau1::Real
    beta1::Real
    theta::Real

    end
x = params_struct(a=4, b=1.2)

x = (a=1, b=(c=3, d=4))
x

@set x.b.c = 10 # nested update
x



b = Dict(Pair.(A.var, A.default))
b

b["tau1"]

# create named tuple to allow dot access
@namedtuple(param=A.var, default=A.default)



vars = Dict("hmm1"=>Dict("trans"=>1, "means"=>2, "vars"=>3)) ;
hmm1 = (; (Symbol(k) => v for (k,v) in vars["hmm1"])...)

nt = (; (Symbol(k) => v for (k,v) in b["b"])...)

vars = Dict("hmm1"=>Dict("trans"=>1, "means"=>2, "vars"=>3)) 




@with_kw mutable struct params_struct
    tau1::Real
    beta1::Real
    end
x = params_struct(a=4,b=1.2)



cnames = ir_gen[1, :]
NamedArray(ir_gen, ([], [cnames]))
NamedArray(ir_gen, (["row1", "row2"], []))

struct MyStruct
    a::Int
    b::Real
    grid::Matrix{Float64}
end

function MyStruct(a::Int, b::Real)::MyStruct
    grid = zeros(Float64, a, a,)
    grid[1, 2:end-1] .= b
    grid[2:end-1, end] .= b
    return MyStruct(a, b, grid)
end


convert(Struct, ir_gen)

# bond index "h6:l11"
bonds = sh["H6:L11"]
XLSX.readtable(filename, )

df = DataFrame(XLSX.readtable("myfile.xlsx", "mysheet"))

df = DataFrame(XLSX.readtable("myfile.xlsx", "mysheet"))



## end cell
wb = XLSX.readxlsx(file_name)
XLSX.sheetnames(wb)

# https://felipenoris.github.io/XLSX.jl/stable/tutorial/
wb = XLSX.readxlsx(file_name)
XLSX.sheetnames(wb)

# get the first sheet
sheet = wb[1]
sheet = wb["Parameters"]
sheet["I7"]

## end of cell
# get the first sheet
sheet = wb[1]


# Pkg.add("XLSX")

## test 1


@with_kw mutable struct params_struct
    a::Int
    b::Real
    end

x = params_struct(a=4,b=1.2)

x = params_struct(a=4,b=1.2)

x
x.a
x.a = 7
x

# x=params_struct
# x
# x.a = 2
# x.b = 3.0
# x = params_struct(a=3, b=12.1)


## cell one use alt-enter to execute cell block, shift-enter to execute line
x =4
y=87

## cell two

z=y+x
z


π
ϕ  # phi
ω  # omega
Ω  # Omega



@with_kw struct foo
        a::Int
        b::Real
        grid::Matrix{Float64} = g(a,b)
        end




