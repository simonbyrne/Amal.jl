"""
    exp2(x)

Compute the base ``2`` exponential of ``x``, in other words ``2^x``.
"""
function exp2 end

#  Method
#    1. Argument reduction: Reduce x to an r so that |r| <= 0.5. Given x,
#       find r and integer k such that
#
#                x = k + r,  |r| <= 0.5.
#
#    2. Approximate exp2(r) by a polynomial on the interval [-0.5, 0.5]:
#
#           exp2(x) = 1.0 + polynomial(x),
#
#    3. Scale back: exp(x) = 2^k * exp2(r)

@inline @oftype _exp2{T}(x::T) = 1 + x *
    (0.69314718055994528622676398299518041312694549560547 + x *
    (0.240226506959100721827482516346208285540342330932617 + x *
    (5.5504108664824178265284615463315276429057121276855e-2 + x *
    (9.6181291076279495227963067804921593051403760910034e-3 + x *
    (1.3333558145596998995713322599954153702128678560257e-3 + x *
    (1.54035303943367583639698081832136722368886694312096e-4 + x *
    (1.52527349442039454277151785954735885297850472852588e-5 + x *
    (1.32154860378320582490812781784050855549139669165015e-6 + x *
    (1.0177326010671100832321228418439473806245132436743e-7 + x *
    (7.0551770482863980866023478660982448662508659253945e-9 + x *
    (4.6887051828071687937460286567403246194007948588478e-10 + x *
    (2.535123436487133587891076626399781707849045986336e-11 + x *
    (-2.8554282403321170096020279832175396781540621660156e-11)))))))))))))

@inline @oftype _exp2{T<:SmallFloatTypes}(x::T) = 1 + x *
    (0.693147182464599609375 + x *
    (0.2402265071868896484375 + x *
    (5.5504046380519866943359375e-2 + x *
    (9.61808301508426666259765625e-3 + x *
    (1.33385811932384967803955078125e-3 + x *
    (1.5453874948434531688690185546875e-4 + x *
    1.412333585903979837894439697265625e-5))))))

function exp2{T}(x::T)
    # reduce
    k = round(x)
    n = _trunc(k)
    r = x - k

    # compute approximation
    u = _exp2(r)
    u = _ldexp(u,n)

    u = ifelse(x == T(Inf), T(Inf), u)
    u = ifelse(x == T(-Inf), T(0.0), u)
    return u
end
