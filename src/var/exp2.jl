"""
    exp2(x)

Compute the base ``2`` exponential of ``x``, in other words ``2^x``.
"""
function exp2 end

# Method: see exp.jl, same idea except we do not have the hi, lo argument split in this case

@inline @oftype_float function _exp2{T}(r::T)
    z = r*r
    p = @horner(z, 2.88539008177792677400930188014172017574310302734375,
    0.115524530093332036817521668581321137025952339172363,
    -9.250684781849213746823812343222925846930593252182e-4,
    1.05822000158343272786798383577888671425171196460724e-5,
    -1.27252931902732029818351160328770976803980374825187e-7,
    2.6526424069598856723727903222801241533979066389293e-9,
    -4.8026082265053178331580863743947851229876278011943e-9,
    1.09349819883553889463835066234338733170972091102158e-8,
    -1.0291711169715280981556705100152249166001183766639e-8)
    return 1.0 + 2.0*r/(p - r)
end

@inline @oftype_float function _exp2{T<:SmallFloatTypes}(r::T)
    z = r*r
    p = @horner(z, 2.88539028167724609375,
    0.11550854146480560302734375,
    -5.66951814107596874237060546875e-4,
    -3.2634953968226909637451171875e-3,
    1.30958743393421173095703125e-2,
    -1.904843747615814208984375e-2)
    return 1.0 + 2.0*r/(p - r)
end

@oftype_float function exp2{T}(x::T)
    x > MAXEXP2(T) && return Inf
    x < MINEXP2(T) && return 0.0
 
    # reduce
    k = round(x) 
    n = _trunc(k)
    r = x - k

    # compute approximation
    x = _exp2(r)
    return _ldexp(x,n)
end