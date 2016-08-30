"""
Return binary exponent of d as an Integer.
"""
function xilogb{T<:FloatTypes}(d::T)
    e = ilogbp1(abs(d)) - 1
    e = d == 0   ? typemin(Int) : e
    e = isinf(d) ? typemax(Int) : e
    e = isnan(d) ? typemax(Int) : e
    return e 
end

function xlog_u1(d::Float64)
    s = logk(d)
    x = s.x + s.y

    isinf(d) && (x = Inf)
    d < 0    && (x = NaN)
    d == 0   && (x = -Inf)
    return x
end

function xlog10(a::Float64)
    d = ddmul_d2_d2_d2(logk(a), Double2(0.43429448190325176116, 6.6494347733425473126e-17))
    x = d.x + d.y
    isinf(a) && (x = Inf)
    a < 0    && (x = NaN)
    a == 0   && (x = -Inf)
    return x
end

function xlog1p(a::Float64)
    d = logk2(ddadd2_d2_d_d(a, 1.0))
    x = d.x + d.y
    isinf(a) && (x = Inf)
    a < -1   && (x = NaN)
    a == -1  && (x = -Inf)
    return x
end

let
global xlog
const c8 = 0.148197055177935105296783
const c7 = 0.153108178020442575739679
const c6 = 0.181837339521549679055568
const c5 = 0.22222194152736701733275
const c4 = 0.285714288030134544449368
const c3 = 0.399999999989941956712869
const c2 = 0.666666666666685503450651
const c1 = 2

function xlog(d::Float64)
    e = ilogbp1(d*0.7071)
    m = ldexpk(d,-e)
    x = (m-1)/(m+1)
    x2 = x*x
    t = @horner x2 c1 c2 c3 c4 c5 c6 c7 c8
    x = x * t + 0.693147180559945286226764 * e
    isinf(d) && (x = Inf)
    d < 0    && (x = NaN)
    d == 0   && (x = -Inf)
    return x
end
end