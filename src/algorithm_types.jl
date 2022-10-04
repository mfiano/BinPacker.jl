abstract type SortingAlgorithm end

struct SortByNothing <: SortingAlgorithm end
struct SortByRandom <: SortingAlgorithm end
struct SortByWidth <: SortingAlgorithm end
struct SortByHeight <: SortingAlgorithm end
struct SortByPerimeter <: SortingAlgorithm end
struct SortByArea <: SortingAlgorithm end
struct SortByEdgeDifference <: SortingAlgorithm end
struct SortByAspectRatio <: SortingAlgorithm end
struct SortByShortestEdge <: SortingAlgorithm end
struct SortByLongestEdge <: SortingAlgorithm end

sorting_algorithm_value(::Val{:none}) = SortByNothing()
sorting_algorithm_value(::Val{:random}) = SortByRandom()
sorting_algorithm_value(::Val{:width}) = SortByWidth()
sorting_algorithm_value(::Val{:height}) = SortByHeight()
sorting_algorithm_value(::Val{:perimeter}) = SortByPerimeter()
sorting_algorithm_value(::Val{:area}) = SortByArea()
sorting_algorithm_value(::Val{:edge_difference}) = SortByEdgeDifference()
sorting_algorithm_value(::Val{:aspect_ratio}) = SortByAspectRatio()
sorting_algorithm_value(::Val{:shortest_edge}) = SortByShortestEdge()
sorting_algorithm_value(::Val{:longest_edge}) = SortByLongestEdge()

@inline sort_rects!(rects, by::F; rev=true) where {F} = sort!(rects, by=by, rev=rev)
@inline sort_rects!(rects, ::SortByNothing) = rects
@inline sort_rects!(rects, ::SortByRandom) = shuffle!(rects)
@inline sort_rects!(rects, ::SortByWidth) = sort_rects!(rects, width)
@inline sort_rects!(rects, ::SortByHeight) = sort_rects!(rects, height)
@inline sort_rects!(rects, ::SortByPerimeter) = sort_rects!(rects, perimeter)
@inline sort_rects!(rects, ::SortByArea) = sort_rects!(rects, area)
@inline sort_rects!(rects, ::SortByEdgeDifference) = sort_rects!(rects, edge_difference, rev=false)
@inline sort_rects!(rects, ::SortByAspectRatio) = sort_rects!(rects, aspect_ratio, rev=false)

@inline function sort_rects!(rects, ::SortByShortestEdge)
    sort_rects!(sort_rects!(rects, longest_edge), shortest_edge)
end

@inline function sort_rects!(rects, ::SortByLongestEdge)
    sort_rects!(sort_rects!(rects, shortest_edge), longest_edge)
end

abstract type FitnessAlgorithm end

struct EdgeFit <: FitnessAlgorithm end
struct AreaFit <: FitnessAlgorithm end

fitness_algorithm_value(::Val{:edge}) = EdgeFit()
fitness_algorithm_value(::Val{:area}) = AreaFit()

abstract type BinSelectionAlgorithm end

struct SelectFirstFit <: BinSelectionAlgorithm end
struct SelectBestFit <: BinSelectionAlgorithm end

bin_selection_algorithm_value(::Val{:first_fit}) = SelectFirstFit()
bin_selection_algorithm_value(::Val{:best_fit}) = SelectBestFit()

abstract type BinPolicyAlgorithm end

struct AutoResizeBin <: BinPolicyAlgorithm end
struct AutoCreateBin <: BinPolicyAlgorithm end

bin_policy_algorithm_value(::Val{:resize}) = AutoResizeBin()
bin_policy_algorithm_value(::Val{:create}) = AutoCreateBin()
