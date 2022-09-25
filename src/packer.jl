struct Packer{S <: SortingMetric, F <: FitnessMetric}
    width::Int
    height::Int
    free_space::Vector{Rect}
    allow_rotations::Bool
    sorting_metric::S
    fitness_metric::F
end

function packer(w, h; allow_rotations=false, sorting_metric=:perimeter, fitness_metric=:area)
    free_space = Rect[rect(w, h)]
    sorting_metric = sorting_metric_value(Val(sorting_metric))
    fitness_metric = fitness_metric_value(Val(fitness_metric))
    Packer(w, h, free_space, allow_rotations, sorting_metric, fitness_metric)
end

function find_free_rect(packer, placed)
    free_space = packer.free_space
    allow_rotations = packer.allow_rotations
    metric = packer.fitness_metric
    total_score = typemax(Int32)
    best = nothing
    for free ∈ free_space
        if free.w ≥ placed.w && free.h ≥ placed.h
            score = fitness(free, placed, metric)
            if score < total_score
                best = free.x, free.y, false
                total_score = score
            end
        end
        if allow_rotations
            if free.w ≥ placed.h && free.h ≥ placed.w
                score = fitness(free, placed, metric)
                if score < total_score
                    best = free.x, free.y, true
                    total_score = score
                end
            end
        end
    end
    if !isnothing(best)
        x, y, rotated = best
        if rotated
            placed.w, placed.h, placed.rotated = placed.h, placed.w, true
        end
        placed.x, placed.y = x, y
        placed
    else
        error("Cannot pack anymore rects")
    end
end

function partition_free_space(free_space, placed)
    old = Rect[]
    new = Rect[]
    foreach(free_space) do r1
        if !intersects(r1, placed, Adjacent())
            push!(old, r1)
        else
            if intersects(r1, placed, Overlap())
                r2 = placed
                r1.r > r2.x > r1.x && push!(new, rect(r2.x - r1.x, r1.h, r1.x, r1.y))
                r1.r > r2.r > r1.x && push!(new, rect(r1.r - r2.r, r1.h, r2.r, r1.y))
                r1.t > r2.y > r1.y && push!(new, rect(r1.w, r2.y - r1.y, r1.x, r1.y))
                r1.t > r2.t > r1.y && push!(new, rect(r1.w, r1.t - r2.t, r1.x, r2.t))
            else
                push!(new, r1)
            end
        end
    end
    old, new
end

function clean_free!(new)
    i = 1
    len = length(new)
    while i ≤ len
        j = i + 1
        x = new[i]
        while j ≤ len
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
    nothing
end

function prune_free_space!(free_space, placed)
    old, new = partition_free_space(free_space, placed)
    copy!(free_space, old)
    clean_free!(new)
    append!(free_space, new)
    nothing
end

@inline function place_rect(packer, rect)
    placed = find_free_rect(packer, rect)
    prune_free_space!(packer.free_space, placed)
    placed
end

function pack(packer, rects)
    metric = packer.sorting_metric
    map(sort_rects(rects, metric)) do x
        place_rect(packer, x)
    end
end
