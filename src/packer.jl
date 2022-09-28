struct Packer{SM <: SortingMetric, BS <: BinSelectionMethod}
    bins::Vector{Bin}
    sort_by::SM
    select_by::BS
end

function make_packer(; sort_by=:perimeter, select_by=:first_fit)
    sort_by = sorting_metric_value(Val(sort_by))
    select_by = bin_selection_value(Val(select_by))
    Packer(Bin[], sort_by, select_by)
end

add_bin!(packer::Packer, bin::Bin) = push!(packer.bins, bin)
add_bin!(packer::Packer) = add_bin!(packer, make_bin(2048, 2048))

function select_bin(packer::Packer, rect)
    index = select_bin(packer, packer.select_by, rect)
    iszero(index) && error("Cannot pack anymore rects")
    packer.bins[index]
end

function select_bin(packer::Packer, ::SelectFirstFit, rect)
    index = findfirst(packer.bins) do bin
        fits, _ = find_free_space(bin, rect)
        fits
    end
    !isnothing(index) ? index : 0
end

function select_bin(packer::Packer, ::SelectBestFit, rect)
    best = typemax(Int32)
    index = 0
    for (i, bin) ∈ pairs(packer.bins)
        fits, score = find_free_space(bin, rect)
        if fits && score < best
            best = score
            index = i
        end
    end
    index
end

function pack(packer::Packer, rects)
    isempty(packer.bins) && add_bin!(packer)
    sort_by = packer.sort_by
    rects = deepcopy(rects)
    foreach(sort_rects(rects, sort_by)) do rect
        bin = select_bin(packer, rect)
        place_rect!(bin, rect)
    end
    packer.bins
end
