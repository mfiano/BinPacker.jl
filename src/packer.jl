struct Packer{F <: FitnessAlgorithm, S <: SortingAlgorithm, B <: BinSelectionAlgorithm}
    bins::Vector{Bin{F}}
    bin_options::BinOptions{F}
    sort_by::S
    select_by::B
    auto_bin::Bool
end

function Base.show(io::IO, obj::Packer)
    type = obj |> typeof
    rect_count = mapreduce(x -> x.rects |> length, +, obj.bins, init=0)
    bin_count = obj.bins |> length
    print(io, "$type(:rects => $rect_count, :bins => $bin_count)")
end

function Packer(;
    sort_by=:perimeter,
    fit_by=:area,
    select_by=:first_fit,
    min_size=(128, 128),
    max_size=(4096, 4096),
    padding=0,
    border=0,
    rotate=false,
    resize_by=(2, 2),
    pow2=false,
    square=false,
    auto_bin=false
)
    sort_by = sorting_algorithm_value(Val(sort_by))
    select_by = bin_selection_algorithm_value(Val(select_by))
    bin_options =
        BinOptions(min_size, max_size, padding, border, rotate, resize_by, pow2, square, fit_by)
    default_bin_size = (1, 1) .+ padding .+ 2border
    default_bin = Bin(default_bin_size..., bin_options)
    Packer([default_bin], bin_options, sort_by, select_by, auto_bin)
end

function has_resized_bin(packer, w, h)
    _, bin_index = findmin(area, packer.bins)
    bin = packer.bins[bin_index]
    p = bin.options.padding
    b = bin.options.border
    (w, h) = (w, h) .+ p
    (x, y) = (bin.width, bin.height) .+ p .- b
    if bin.width > bin.height
        return (resize_bin!(bin, Rect(w, h, b + 1, y)) || resize_bin!(bin, Rect(w, h, x, b + 1)))
    else
        return (resize_bin!(bin, Rect(w, h, x, b + 1)) || resize_bin!(bin, Rect(w, h, b + 1, y)))
    end
    false
end

function select_bin(packer::Packer, rect::Rect)
    index = select_bin(packer, rect, packer.select_by)
    if iszero(index)
        if has_resized_bin(packer, rect.w, rect.h)
            return select_bin(packer, rect)
        end
        if packer.auto_bin
            options = packer.bin_options
            p = options.padding + 1
            bin = Bin(rect.w + p, rect.h + p, options)
            push!(packer.bins, bin)
            return select_bin(packer, rect)
        else
            error("Cannot pack anymore rectangles")
        end
    end
    packer.bins[index]
end

function select_bin(packer::Packer, rect::Rect, ::SelectFirstFit)
    index = findfirst(packer.bins) do bin
        fits, _ = find_free_space(bin, rect)
        fits
    end
    !isnothing(index) ? index : 0
end

function select_bin(packer::Packer, rect::Rect, ::SelectBestFit)
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
    isempty(packer.bins) && error("Packer has no bins")
    sort_by = packer.sort_by
    rects = deepcopy(rects)
    foreach(sort_rects(rects, sort_by)) do rect
        bin = select_bin(packer, rect)
        place_rect!(bin, rect)
    end
    packer.bins
end
