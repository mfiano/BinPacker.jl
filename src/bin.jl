mutable struct Bin{F <: FitnessMetric}
    width::Int
    height::Int
    free_space::Vector{Rect}
    target::Rect
    rects::Vector{Rect}
    padding::Int
    border::Int
    pot::Bool
    rotate::Bool
    fit_by::F
end

function make_bin(width, height; padding=0, border=0, pot=false, rotate=false, fit_by=:area)
    if pot
        width, height = nextpow.(2, (width, height))
    end
    free_size = (width, height) .- (2border - padding)
    free_origin = (border + 1, border + 1)
    free = _make_rect(free_size..., free_origin...)
    fit_by = fitness_metric_value(Val(fit_by))
    Bin(width, height, Rect[free], make_rect(0, 0), Rect[], padding, border, pot, rotate, fit_by)
end

function find_free_space(bin::Bin, rect)
    free_space = bin.free_space
    rotate = bin.rotate
    fit_by = bin.fit_by
    total_score = typemax(Int32)
    best = nothing
    target = bin.target
    target.w, target.h = (rect.w, rect.h) .+ bin.padding
    target.x, target.y = rect.x, rect.y
    for free ∈ free_space
        if free.w ≥ target.w && free.h ≥ target.h
            score = fitness(free, target, fit_by)
            if score < total_score
                best = free.x, free.y, false
                total_score = score
            end
        end
        if rotate
            if free.w ≥ target.h && free.h ≥ target.w
                target.w, target.h = target.h, target.w
                score = fitness(free, target, fit_by)
                target.h, target.w = target.w, target.h
                if score < total_score
                    best = free.x, free.y, true
                    total_score = score
                end
            end
        end
    end
    if !isnothing(best)
        target.x, target.y, target.rotated = best
        true, total_score
    else
        false, typemax(Int32)
    end
end

function partition_free_space(bin::Bin)
    old = Rect[]
    new = Rect[]
    rect = bin.target
    foreach(bin.free_space) do r1
        if !intersects(r1, rect, Adjacent())
            push!(old, r1)
        elseif intersects(r1, rect, Overlap())
            r2 = rect
            r1.r > r2.x > r1.x && push!(new, _make_rect(r2.x - r1.x, r1.h, r1.x, r1.y))
            r1.r > r2.r > r1.x && push!(new, _make_rect(r1.r - r2.r, r1.h, r2.r, r1.y))
            r1.t > r2.y > r1.y && push!(new, _make_rect(r1.w, r2.y - r1.y, r1.x, r1.y))
            r1.t > r2.t > r1.y && push!(new, _make_rect(r1.w, r1.t - r2.t, r1.x, r2.t))
        else
            push!(new, r1)
        end
    end
    old, new
end

function prune_free_space!(bin::Bin)
    old, new = partition_free_space(bin)
    copy!(bin.free_space, old)
    i = 1
    len = length(new)
    while i < len
        j = i + 1
        x = new[i]
        while j <= len
            y = new[j]
            if contains(y, x)
                deleteat!(new, i)
                i -= 1
                len -= 1
                break
            end
            if contains(x, y)
                deleteat!(new, j)
                j -= 1
                len -= 1
            end
            j += 1
        end
        i += 1
    end
    append!(bin.free_space, new)
    nothing
end

@inline function place_rect!(bin::Bin, rect)
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
