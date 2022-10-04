mutable struct Bin{F <: FitnessAlgorithm}
    width::Int
    height::Int
    free_space::Vector{Rect}
    target::Rect
    rects::Vector{Rect}
    options::BinOptions{F}
end

function Base.show(io::IO, obj::Bin)
    (; width, height) = obj
    type = obj |> typeof
    rect_count = obj.rects |> length
    efficiency = round(packing_efficiency(obj) * 100, digits=2)
    print(io, "$width×$height $type(:rects => $rect_count, :efficiency => $efficiency)")
end

function Bin(width, height, options)
    border = options.border
    padding = options.padding
    free_size = (width, height) .- (2border - padding)
    free_origin = (border + 1, border + 1)
    free = Rect(free_size..., free_origin...)
    Bin(width, height, Rect[free], Rect(0, 0), Rect[], options)
end

@inline area(bin::Bin) = bin.width * bin.height

@inline function rect(bin::Bin)
    p = bin.options.padding
    b = bin.options.border
    size = (bin.width, bin.height) .- (2b - p)
    origin = (b + 1, b + 1)
    Rect(size..., origin...)
end

function find_free_space(bin::Bin, rect::Rect)
    free_space = bin.free_space
    rotate = bin.options.rotate
    fit_by = bin.options.fit_by
    best_score = typemax(Int32)
    best = nothing
    target = bin.target
    target.w, target.h = (rect.w, rect.h) .+ bin.options.padding
    target.x, target.y = rect.x, rect.y
    for free ∈ free_space
        if free.w ≥ target.w && free.h ≥ target.h
            score = fitness(free, target, fit_by)
            if score < best_score
                best = free.x, free.y, false
                best_score = score
            end
        end
        if rotate
            if free.w ≥ target.h && free.h ≥ target.w
                target.w, target.h = target.h, target.w
                score = fitness(free, target, fit_by)
                target.h, target.w = target.w, target.h
                if score < best_score
                    best = free.x, free.y, true
                    best_score = score
                end
            end
        end
    end
    if !isnothing(best)
        target.x, target.y, target.rotated = best
        true, best_score
    else
        false, typemax(Int32)
    end
end

function partition_free_space(bin::Bin)
    old = Rect[]
    new = Rect[]
    r2 = bin.target
    foreach(bin.free_space) do r1
        if !intersects(r1, r2, Adjacent())
            push!(old, r1)
        elseif intersects(r1, r2, Overlap())
            r1.r > r2.x > r1.x && push!(new, Rect(r2.x - r1.x, r1.h, r1.x, r1.y))
            r1.r > r2.r > r1.x && push!(new, Rect(r1.r - r2.r, r1.h, r2.r, r1.y))
            r1.t > r2.y > r1.y && push!(new, Rect(r1.w, r2.y - r1.y, r1.x, r1.y))
            r1.t > r2.t > r1.y && push!(new, Rect(r1.w, r1.t - r2.t, r1.x, r2.t))
        else
            push!(new, r1)
        end
    end
    old, new
end

function clean_free_space!(free_space)
    i = 1
    len = length(free_space)
    while i < len
        j = i + 1
        r1 = free_space[i]
        while j <= len
            r2 = free_space[j]
            if contains(r2, r1)
                deleteat!(free_space, i)
                i -= 1
                len -= 1
                break
            end
            if contains(r1, r2)
                deleteat!(free_space, j)
                j -= 1
                len -= 1
            end
            j += 1
        end
        i += 1
    end
end

function prune_free_space!(bin::Bin)
    old, new = partition_free_space(bin)
    copy!(bin.free_space, old)
    clean_free_space!(new)
    append!(bin.free_space, new)
    nothing
end

@inline function place_rect!(bin::Bin, rect::Rect)
    target = bin.target
    if target.rotated
        target.w, target.h = target.h, target.w
        rect.w, rect.h = rect.h, rect.w
    end
    rect.x, rect.y, rect.rotated = target.x, target.y, target.rotated
    prune_free_space!(bin)
    push!(bin.rects, rect)
    nothing
end

function packing_efficiency(bin::Bin)
    border = bin.options.border
    padding = bin.options.padding
    used_area = mapreduce(x -> (x.w, x.h) .+ padding |> prod, +, bin.rects, init=0)
    total_area = (bin.width, bin.height) .- (2border - padding) |> prod
    used_area / total_area
end

function resize_bin!(bin::Bin, rect::Rect)
    p = bin.options.padding - 1
    b = bin.options.border
    max_width, max_height = bin.options.max_size
    w = max(bin.width, rect.r - p + b)
    h = max(bin.height, rect.t - p + b)
    if bin.options.rotate
        rw = max(bin.width, rect.x + rect.h - p + b)
        rh = max(bin.height, rect.y + rect.w - p + b)
        if rw * rh < w * h
            w = rw
            h = rh
        end
    end
    w, h = ((a, b) -> a + mod(-a, b)).((w, h), bin.options.resize_by)
    if bin.options.pow2
        w, h = nextpow.(2, (w, h))
    end
    if bin.options.square
        w = h = max(w, h)
    end
    if w > max_width || h > max_height
        return false
    end
    expand_free_space!(bin, w + p, h + p)
    bin.width, bin.height = w, h
    true
end

function resize_bin!(bin::Bin, w, h)
    p = bin.options.padding
    b = bin.options.border
    w, h = (w, h) .+ p
    x, y = (bin.width, bin.height) .+ p .- b
    if bin.width > bin.height
        resize_bin!(bin, Rect(w, h, b + 1, y)) || resize_bin!(bin, Rect(w, h, x, b + 1))
    else
        resize_bin!(bin, Rect(w, h, x, b + 1)) || resize_bin!(bin, Rect(w, h, b + 1, y))
    end
end

function expand_free_space!(bin::Bin, w, h)
    p = bin.options.padding
    b = bin.options.border
    foreach(bin.free_space) do rect
        if rect.r ≥ min(bin.width + p - b)
            rect.w = w - rect.x - b
        end
        if rect.t ≥ min(bin.height + p - b)
            rect.h = h - rect.y - b
        end
    end
    push!(bin.free_space, Rect(w - bin.width - p, h - 2b, bin.width + p - b, b + 1))
    push!(bin.free_space, Rect(w - 2b, h - bin.height - p, b + 1, bin.height + p - b))
    filter!(bin.free_space) do rect
        rect.w > 0 && rect.h > 0 && rect.x ≥ b && rect.y ≥ b
    end
    clean_free_space!(bin.free_space)
    nothing
end
