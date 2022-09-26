struct Packer{S <: SortingMetric}
    bins::Vector{Bin}
    sort_by::S
end

function packer(; sort_by=:perimeter)
    sort_by = sorting_metric_value(Val(sort_by))
    Packer(Bin[], sort_by)
end

add_bin!(packer::Packer, bin::Bin) = push!(packer.bins, bin)
add_bin!(packer::Packer) = add_bin!(packer, make_bin(2048, 2048))

@inline find_bin(packer::Packer) = first(packer.bins)

function pack(packer::Packer, rects)
    isempty(packer.bins) && add_bin!(packer)
    metric = packer.sort_by
    rects = deepcopy(rects)
    foreach(sort_rects(rects, metric)) do x
        bin = find_bin(packer)
        place_rect!(bin, x)
    end
    packer.bins
end
