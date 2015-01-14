-- https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline

local function sqr_dist(x0, y0, x1, y1)
    return (x0-x1)*(x0-x1) + (y0-y1)*(y0-y1)
end

local function dist(x0, y0, x1, y1)
    return math.sqrt(sqr_dist(x0, y0, x1, y1))
end

local t0, t1, t2, t3
local x0, y0, x1, y1, x2, y2, x3, y3
local alpha
local precision
local ans

local function point(t)
    local x01 = (t1-t)/(t1-t0)*x0 + (t-t0)/(t1-t0)*x1
    local y01 = (t1-t)/(t1-t0)*y0 + (t-t0)/(t1-t0)*y1

    local x12 = (t2-t)/(t2-t1)*x1 + (t-t1)/(t2-t1)*x2
    local y12 = (t2-t)/(t2-t1)*y1 + (t-t1)/(t2-t1)*y2

    local x23 = (t3-t)/(t3-t2)*x2 + (t-t2)/(t3-t2)*x3
    local y23 = (t3-t)/(t3-t2)*y2 + (t-t2)/(t3-t2)*y3

    local x012 = (t2-t)/(t2-t0)*x01 + (t-t0)/(t2-t0)*x12
    local y012 = (t2-t)/(t2-t0)*y01 + (t-t0)/(t2-t0)*y12

    local x123 = (t3-t)/(t3-t1)*x12 + (t-t1)/(t3-t1)*x23
    local y123 = (t3-t)/(t3-t1)*y12 + (t-t1)/(t3-t1)*y23

    local x1234 = (t2-t)/(t2-t1)*x012 + (t-t1)/(t2-t1)*x123
    local y1234 = (t2-t)/(t2-t1)*y012 + (t-t1)/(t2-t1)*y123

    return x1234, y1234
end

local function calc_t()
    t0 = 0
    t1 = t0 + math.pow(sqr_dist(x0, y0, x1, y1), alpha/2)
    t2 = t1 + math.pow(sqr_dist(x1, y1, x2, y2), alpha/2)
    t3 = t2 + math.pow(sqr_dist(x2, y2, x3, y3), alpha/2)
end

local function seg(px1, py1, pt1, px2, py2, pt2)
    if sqr_dist(px1, py1, px2, py2) <= precision then
        table.insert(ans, px1)
        table.insert(ans, py1)
        return
    end

    local pt3 = (pt1 + pt2) / 2
    local px3, py3 = point(pt3)
    seg(px1, py1, pt1, px3, py3, pt3)
    seg(px3, py3, pt3, px2, py2, pt2)
end

function catmull_rom(px0, py0, px1, py1, px2, py2, px3, py3, pprecision, palpha)
    x1, y1 = px1, py1
    x2, y2 = px2, py2
    alpha = palpha or 0.5
    precision = pprecision*pprecision

    if sqr_dist(x1, y1, x2, y2) <= precision then
        return {x1, y1, x2, y2}
    end

    if px0 == nil or sqr_dist(px0, py0, x1, y1) <= precision then
        x0 = 2*x1-x2
        y0 = 2*y1-y2
    else
        x0, y0 = px0, py0
    end

    if px3 == nil or sqr_dist(px3, py3, x2, y2) <= precision then
        x3 = 2*x2-x1
        y3 = 2*y2-y1
    else
        x3, y3 = px3, py3
    end

    calc_t()

    it0 = t1
    ix0, iy0 = point(it0)
    it1 = t2
    ix1, iy1 = point(it1)

    ans = {}
    seg(ix0, iy0, it0, ix1, iy1, it1)
    table.insert(ans, ix1)
    table.insert(ans, iy1)
    return ans
end


