using Amal
# using Sleef
# using Cephes
using BenchmarkTools
using JLD 
using DataStructures
using Suppressor 

testlib = "Amal"
reflib  = "Base"
test_types = (Float64, Float32) # Which types do you want to bench?

const RETUNE  = false
const VERBOSE = true
const DETAILS = false

bench_reduce(f::Function, X) = mapreduce(x -> reinterpret(Unsigned,x), |, f(x) for x in X)

function modulefunex(str) # convert e.g. "Libm.Cephes.exp" to an Expr you can actually call :P
    g = split(str,".")
    if length(g) > 1
        return Expr(:., modulefunex(join(g[1:end-1],".")), QuoteNode(Symbol(g[end])))
    end
    return Symbol(str)
end

import Base.atanh
for f in (:atanh,)
    @suppress @eval begin
        ($f)(x::Float64) = ccall(($(string(f)),Base.libm_name), Float64, (Float64,), x)
        ($f)(x::Float32) = ccall(($(string(f,"f")),Base.libm_name), Float32, (Float32,), x)
    end
end

inttype(::Type{Float64}) = Int64
inttype(::Type{Float32}) = Int32
inttype(::Type{Float16}) = Int16

function run_bench(bench, test_types)
    suite = BenchmarkGroup()
    for n in bench
        suite[n] = BenchmarkGroup([n])
    end

    MRANGE(::Type{Float64}) = 10000000
    MRANGE(::Type{Float32}) = 10000

    x_trig{T}(::Type{T}) = begin
        x_trig = T[]
        for i = 1:10000
            s = reinterpret(T, reinterpret(inttype(T), T(pi)/4 * i) - inttype(T)(20))
            e = reinterpret(T, reinterpret(inttype(T), T(pi)/4 * i) + inttype(T)(20))
            d = s
            while d <= e 
                append!(x_trig, d)
                d = reinterpret(T, reinterpret(inttype(T), d) + inttype(T)(1))
            end
        end
        x_trig = append!(x_trig, -10:0.0002:10)
        x_trig = append!(x_trig, -MRANGE(T):200.1:MRANGE(T))
    end
    x_exp{T}(::Type{T})        = map(T, vcat(-10:0.0002:10, -50:0.01:50))
    x_exp2{T}(::Type{T})       = map(T, vcat(-10:0.0002:10, -120:0.023:1000, -1000:0.02:2000))
    x_exp10{T}(::Type{T})      = map(T, vcat(-10:0.0002:10, -35:0.023:1000, -300:0.01:300))
    x_expm1{T}(::Type{T})      = map(T, vcat(-10:0.0002:10, -1000:0.021:1000, -1000:0.023:1000, 10.0.^-(0:0.02:300), -10.0.^-(0:0.02:300), 10.0.^(0:0.021:300), -10.0.^-(0:0.021:300)))
    x_log{T}(::Type{T})        = map(T, vcat(0.0001:0.0001:10, 0.001:0.1:10000, 1.1.^(-1000:1000), 2.1.^(-1000:1000)))
    x_log10{T}(::Type{T})      = map(T, vcat(0.0001:0.0001:10, 0.0001:0.1:10000))
    x_log1p{T}(::Type{T})      = map(T, vcat(0.0001:0.0001:10, 0.0001:0.1:10000, 10.0.^-(0:0.02:300), -10.0.^-(0:0.02:300)))
    x_atrig{T}(::Type{T})      = map(T, vcat(-1:0.00002:1))
    x_atan{T}(::Type{T})       = map(T, vcat(-10:0.0002:10, -10000:0.2:10000, -10000:0.201:10000))
    x_cbrt{T}(::Type{T})       = map(T, vcat(-10000:0.2:10000, 1.1.^(-1000:1000), 2.1.^(-1000:1000)))
    x_trigh{T}(::Type{T})      = map(T, vcat(-10:0.0002:10, -1000:0.02:1000))
    x_asinhatanh{T}(::Type{T}) = map(T, vcat(-10:0.0002:10, -1000:0.02:1000))
    x_acosh{T}(::Type{T})      = map(T, vcat(1:0.0002:10, 1:0.02:1000))
    x_pow{T}(::Type{T}) = begin
        xx1 = map(Tuple{T,T}, [(x,y) for x = -100:0.20:100, y = 0.1:0.20:100])[:]
        xx2 = map(Tuple{T,T}, [(x,y) for x = -100:0.21:100, y = 0.1:0.22:100])[:]
        xx3 = map(Tuple{T,T}, [(x,y) for x = 2.1, y = -1000:0.1:1000])
        xx = vcat(xx1, xx2, xx2)
    end


    micros = OrderedDict(
        # "sin"   => x_trig,
        # "cos"   => x_trig,
        # "tan"   => x_trig,
        # "asin"  => x_atrig,
        # "acos"  => x_atrig,
        # "atan"  => x_atan,
        "exp"   => x_exp,
        "exp2"  => x_exp2,
        "exp10" => x_exp10,
        # "expm1" => x_expm1,
        # "log"   => x_log,
        # "log2"  => x_log10,
        # "log10" => x_log10,
        # "log1p" => x_log1p,
        # "sinh"  => x_trigh,
        # "cosh"  => x_trigh,
        # "tanh"  => x_trigh,
        # "asinh" => x_asinhatanh,
        # "acosh" => x_acosh,
        # "atanh" => x_asinhatanh,
        # "cbrt"  => x_cbrt
        )



    for n in bench
        for (f,x) in micros
            suite[n][f] = BenchmarkGroup([f])
            for T in test_types
                fex = modulefunex(join([n,f],"."))
                suite[n][f][string(T)] = @benchmarkable bench_reduce($fex, $(x(T)))
            end
        end
    end


    tune_params = joinpath(dirname(@__FILE__), "params.jld")
    if !isfile(tune_params) || RETUNE
        tune!(suite; verbose=VERBOSE)
        save(tune_params, "suite", params(suite))
        println("Saving tuned parameters.")
    else
        println("Loading pretuned parameters.")
        loadparams!(suite, load(tune_params, "suite"), :evals, :samples)
    end

    println("Running micro benchmarks...")
    results = run(suite; verbose=VERBOSE)

    print_with_color(:blue, "Benchmarks: median ratio $testlib/$reflib\n")
    for f in keys(micros)
        print_with_color(:magenta, string(f))
        for T in test_types
            println()
            print("time: ", )
            tratio = ratio(median(results[testlib][f][string(T)]), median(results[reflib][f][string(T)])).time
            tcolor = tratio > 3 ? :red : tratio < 1.5 ? :green : :blue
            print_with_color(tcolor, @sprintf("%.2f",tratio), " ", string(T))
            if DETAILS
                print_with_color(:blue, "details $testlib/$reflib\n")
                println(results[testlib][f][string(T)])
                println(results[reflib][f][string(T)])
                println()
            end
        end
        println("\n")
    end
end

run_bench((testlib,reflib),test_types)
