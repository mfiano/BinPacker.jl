struct Bin{F <: FitnessAlgorithm}
    width::Int
    height::Int
    free_space::Vector{Rect}
    target::Rect
    rects::Vector{Rect}
    padding::Int
    border::Int
    rotate::Bool
    fit_by::F
end

function Base.show(io::IO, obj::Bin)
    (; width, height) = obj
    type = obj |> typeof
    rect_count = obj.rects |> length
    efficiency = round(packing_efficiency(obj) * 100, digits=2)
    print(io, "$width×$height $type(:rects => $rect_count, :efficiency => $efficiency%)")
end

function Bin(width, height; padding=0, border=0, rotate=false, fit_by=:area)
    free_size = (width, height) .- (2border - padding)
    free_origin = (border + 1, border + 1)
    free = Rect(free_size..., free_origin...)
    fit_by = fitness_algorithm_value(Val(fit_by))
    Bin(width, height, Rect[free], Rect(0, 0), Rect[], padding, border, rotate, fit_by)
end

function find_free_space(bin::Bin, r::Rect)
    free_space = bin.free_space
    rotate = bin.rotate
    fit_by = bin.fit_by
    total_score = typemax(Int32)
    best = nothing
    target = bin.target
    target.w, target.h = (r.w, r.h) .+ bin.padding
    target.x, target.y = r.x, r.y
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

@inline function place_rect!(bin::Bin, r::Rect)
    target = bin.target
    if target.rotated
        target.w, target.h = target.h, target.w
        r.w, r.h = r.h, r.w
    end
    r.x, r.y, r.rotated = target.x, target.y, target.rotated
    prune_free_space!(bin)
    push!(bin.rects, r)
    nothing
end

function packing_efficiency(bin::Bin)
    border = bin.border
    padding = bin.padding
    rect_area = mapreduce(x -> (x.w, x.h) .+ padding |> prod, +, bin.rects, init=0)
    free_area = (bin.width, bin.height) .- (2border - padding) |> prod
    rect_area / free_area
end
