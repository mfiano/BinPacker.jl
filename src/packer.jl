struct Packer{
    F <: FitnessAlgorithm,
    S <: SortingAlgorithm,
    B <: BinSelectionAlgorithm,
    P <: BinPolicyAlgorithm
}
    bins::Vector{Bin{F}}
    bin_options::BinOptions{F}
    bin_policy::P
    sort_by::S
    select_by::B
end

function Base.show(io::IO, obj::Packer)
    type = obj |> typeof
    rect_count = mapreduce(x -> x.rects |> length, +, obj.bins, init=0)
    bin_count = obj.bins |> length
    print(io, "$type(:rects => $rect_count, :bins => $bin_count)")
end

function validate_option(::Val{:size}, option, value)
    if !(value isa NTuple{2, Int}) || !all(x -> x > 0, value)
        throw(ArgumentError("$option must be a Tuple of 2 positive Int values"))
    end
end

function validate_option(::Val{:non_negative_int}, option, value)
    if !(value isa Int) || value < 0
        throw(ArgumentError("$option must be a non-negative Int value"))
    end
end

function Packer(;
    sort_by=:perimeter,
    fit_by=:area,
    select_by=:first_fit,
    bin_size=(4096, 4096),
    padding=0,
    border=0,
    rotate=false,
    resize_by=(1, 1),
    pow2=false,
    square=false,
    bin_policy=:resize
)
    validate_option(Val(:size), :bin_size, bin_size)
    validate_option(Val(:non_negative_int), :padding, padding)
    validate_option(Val(:non_negative_int), :border, border)
    validate_option(Val(:size), :resize_by, resize_by)
    sort_by = sorting_algorithm_value(Val(sort_by))
    select_by = bin_selection_algorithm_value(Val(select_by))
    bin_policy = bin_policy_algorithm_value(Val(bin_policy))
    bin_options = BinOptions(bin_size, padding, border, rotate, resize_by, pow2, square, fit_by)
    if bin_policy ≡ AutoResizeBin()
        default_bin_size = (1, 1) .+ padding .+ 2border
    elseif bin_policy ≡ AutoCreateBin()
        default_bin_size = bin_size
    end
    default_bin = Bin(default_bin_size..., bin_options)
    Packer([default_bin], bin_options, bin_policy, sort_by, select_by)
end

function handle_unfittable(::AutoResizeBin, packer, rect)
    if resize_bin!(packer.bins[1], rect.w, rect.h)
        select_bin(packer, rect)
    else
        error("Cannot pack anymore rectangles")
    end
end

function handle_unfittable(::AutoCreateBin, packer, rect)
    options = packer.bin_options
    push!(packer.bins, Bin(options.max_size..., options))
    select_bin(packer, rect)
end

function select_bin(packer::Packer, rect::Rect)
    index = select_bin(packer, rect, packer.select_by)
    if iszero(index)
        policy = packer.bin_policy
        handle_unfittable(policy, packer, rect)
    else
        packer.bins[index]
    end
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
    sort_rects!(rects, packer.sort_by)
    foreach(rects) do rect
        bin = select_bin(packer, rect)
        place_rect!(bin, rect)
    end
    packer.bins
end
