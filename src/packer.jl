mutable struct Packer{S <: SortingMetric, F <: FitnessMetric}
    width::Int
    height::Int
    free_space::Vector{Rect}
    border::Int
    padding::Int
    pot::Bool
    rotate::Bool
    sort_by::S
    fit_by::F
end

function packer(
    width,
    height;
    border=0,
    padding=0,
    pot=false,
    rotate=false,
    sort_by=:perimeter,
    fit_by=:area
)
    @assert border ≥ 0
    @assert padding ≥ 0
    sort_by = sorting_metric_value(Val(sort_by))
    fit_by = fitness_metric_value(Val(fit_by))
    packer = Packer(width, height, Rect[], border, padding, pot, rotate, sort_by, fit_by)
    initialize_free_space!(packer)
    packer
end

function initialize_free_space!(packer)
    if packer.pot
        packer.width, packer.height = nextpow.(2, (packer.width, packer.height))
    end
    border = packer.border
    free_size = (packer.width, packer.height) .- border
    free_origin = (border + 1, border + 1)
    push!(packer.free_space, rect(free_size..., free_origin...))
    nothing
end

function find_free_space(packer, rect)
    free_space = packer.free_space
    rotate = packer.rotate
    metric = packer.fit_by
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

function partition_free_space(free_space, new_rect)
    old = Rect[]
    new = Rect[]
    foreach(free_space) do r1
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

function clean_free_space!(free_space)
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

function prune_free_space!(packer, rect)
    free_space = packer.free_space
    old, new = partition_free_space(free_space, rect)
    copy!(free_space, old)
    clean_free_space!(new)
    append!(free_space, new)
    nothing
end

@inline function place_rect!(packer, rect)
    rect.w, rect.h = (rect.w, rect.h) .+ packer.padding
    rect.x, rect.y, rotated = find_free_space(packer, rect)
    if rotated
        rect.w, rect.h, rect.rotated = rect.h, rect.w, true
    end
    prune_free_space!(packer, rect)
    rect.w, rect.h = (rect.w, rect.h) .- packer.padding
    rect
end

function pack(packer, rects)
    metric = packer.sort_by
    map(sort_rects(rects, metric)) do x
        place_rect!(packer, x)
    end
end
