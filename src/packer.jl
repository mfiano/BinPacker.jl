struct Packer{SM <: SortingAlgorithm, BS <: BinSelectionAlgorithm}
    bins::Vector{Bin}
    sort_by::SM
    select_by::BS
end

function Base.show(io::IO, obj::Packer)
    type = obj |> typeof
    rect_count = mapreduce(x -> x.rects |> length, +, obj.bins)
    bin_count = obj.bins |> length
    print(io, "$type(:rects => $rect_count, :bins => $bin_count)")
end

function Packer(; sort_by=:perimeter, select_by=:first_fit)
    sort_by = sorting_algorithm_value(Val(sort_by))
    select_by = bin_selection_algorithm_value(Val(select_by))
    Packer(Bin[], sort_by, select_by)
end

add_bin!(packer::Packer, bin::Bin) = push!(packer.bins, bin)
add_bin!(packer::Packer, w, h) = add_bin!(packer, Bin(w, h))

function select_bin(packer::Packer, r::Rect)
    index = select_bin(packer, r, packer.select_by)
    iszero(index) && error("Cannot pack anymore rects")
    packer.bins[index]
end

function select_bin(packer::Packer, r::Rect, ::SelectFirstFit)
    index = findfirst(packer.bins) do bin
        fits, _ = find_free_space(bin, r)
        fits
    end
    !isnothing(index) ? index : 0
end

function select_bin(packer::Packer, r::Rect, ::SelectBestFit)
    best = typemax(Int32)
    index = 0
    for (i, bin) ∈ pairs(packer.bins)
        fits, score = find_free_space(bin, r)
        if fits && score < best
            best = score
            index = i
        end
    end
    index
end

function pack(packer::Packer, rects)
    isempty(packer.bins) && error("Packer has no bins")
    sort_by = packer.sort_by
    rects = deepcopy(rects)
    foreach(sort_rects(rects, sort_by)) do rect
        bin = select_bin(packer, rect)
        place_rect!(bin, rect)
    end
    packer.bins
end
