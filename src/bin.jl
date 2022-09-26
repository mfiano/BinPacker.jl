mutable struct Bin{F <: FitnessMetric}
    width::Int
    height::Int
    free_space::Vector{Rect}
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
    free_size = (width, height) .- border
    free_origin = (border + 1, border + 1)
    free = rect(free_size..., free_origin...)
    fit_by = fitness_metric_value(Val(fit_by))
    Bin(width, height, Rect[free], Rect[], padding, border, pot, rotate, fit_by)
end

function find_free_space(bin::Bin, rect)
    free_space = bin.free_space
    rotate = bin.rotate
    metric = bin.fit_by
    total_score = typemax(Int32)
    best = nothing
    for free ∈ free_space
        if free.w ≥ rect.w && free.h ≥ rect.h
            score = fitness(free, rect, metric)
            if score < total_score
                best = free.x, free.y, false
                total_score = score
            end
        end
        if rotate
            if free.w ≥ rect.h && free.h ≥ rect.w
                score = fitness(free, rect, metric)
                if score < total_score
                    best = free.x, free.y, true
                    total_score = score
                end
            end
        end
    end
    if !isnothing(best)
        best
    else
        error("Cannot pack anymore rects")
    end
end

function partition_free_space(bin::Bin, new_rect)
    old = Rect[]
    new = Rect[]
    foreach(bin.free_space) do r1
        if !intersects(r1, new_rect, Adjacent())
            push!(old, r1)
        elseif intersects(r1, new_rect, Overlap())
            r2 = new_rect
            r1.r > r2.x > r1.x && push!(new, rect(r2.x - r1.x, r1.h, r1.x, r1.y))
            r1.r > r2.r > r1.x && push!(new, rect(r1.r - r2.r, r1.h, r2.r, r1.y))
            r1.t > r2.y > r1.y && push!(new, rect(r1.w, r2.y - r1.y, r1.x, r1.y))
            r1.t > r2.t > r1.y && push!(new, rect(r1.w, r1.t - r2.t, r1.x, r2.t))
        else
            push!(new, r1)
        end
    end
    old, new
end

function clean_free_space!(::Bin, free_space)
    i = 1
    len = length(free_space)
    while i < len
        j = i + 1
        x = free_space[i]
        while j <= len
            y = free_space[j]
            if contains(y, x)
                deleteat!(free_space, i)
                i -= 1
                len -= 1
                break
            end
            if contains(x, y)
                deleteat!(free_space, j)
                j -= 1
                len -= 1
            end
            j += 1
        end
        i += 1
    end
    nothing
end

function prune_free_space!(bin::Bin, rect)
    free_space = bin.free_space
    old, new = partition_free_space(bin, rect)
    copy!(free_space, old)
    clean_free_space!(bin, new)
    append!(free_space, new)
    nothing
end

@inline function place_rect!(bin::Bin, rect)
    rect.w, rect.h = (rect.w, rect.h) .+ bin.padding
    rect.x, rect.y, rotated = find_free_space(bin, rect)
    if rotated
        rect.w, rect.h, rect.rotated = rect.h, rect.w, true
    end
    prune_free_space!(bin, rect)
    rect.w, rect.h = (rect.w, rect.h) .- bin.padding
    push!(bin.rects, rect)
    nothing
end
