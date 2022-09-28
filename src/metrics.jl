abstract type SortingMetric end

struct SortByNothing <: SortingMetric end
struct SortByRandom <: SortingMetric end
struct SortByWidth <: SortingMetric end
struct SortByHeight <: SortingMetric end
struct SortByPerimeter <: SortingMetric end
struct SortByArea <: SortingMetric end
struct SortByEdgeDifference <: SortingMetric end
struct SortByAspectRatio <: SortingMetric end
struct SortByShortestEdge <: SortingMetric end
struct SortByLongestEdge <: SortingMetric end

sorting_metric_value(::Val{:none}) = SortByNothing()
sorting_metric_value(::Val{:random}) = SortByRandom()
sorting_metric_value(::Val{:width}) = SortByWidth()
sorting_metric_value(::Val{:height}) = SortByHeight()
sorting_metric_value(::Val{:perimeter}) = SortByPerimeter()
sorting_metric_value(::Val{:area}) = SortByArea()
sorting_metric_value(::Val{:edge_difference}) = SortByEdgeDifference()
sorting_metric_value(::Val{:aspect_ratio}) = SortByAspectRatio()
sorting_metric_value(::Val{:shortest_edge}) = SortByShortestEdge()
sorting_metric_value(::Val{:longest_edge}) = SortByLongestEdge()

@inline sort_rects(rects, by::F; rev=true) where {F} = sort!(rects, by=by, rev=rev)
@inline sort_rects(rects, ::SortByNothing) = rects
@inline sort_rects(rects, ::SortByRandom) = shuffle!(rects)
@inline sort_rects(rects, ::SortByWidth) = sort_rects(rects, width)
@inline sort_rects(rects, ::SortByHeight) = sort_rects(rects, height)
@inline sort_rects(rects, ::SortByPerimeter) = sort_rects(rects, perimeter)
@inline sort_rects(rects, ::SortByArea) = sort_rects(rects, area)
@inline sort_rects(rects, ::SortByEdgeDifference) = sort_rects(rects, edge_difference, rev=false)
@inline sort_rects(rects, ::SortByAspectRatio) = sort_rects(rects, aspect_ratio, rev=false)

@inline function sort_rects(rects, ::SortByShortestEdge)
    sort_rects(sort_rects(rects, longest_edge), shortest_edge)
end

@inline function sort_rects(rects, ::SortByLongestEdge)
    sort_rects(sort_rects(rects, shortest_edge), longest_edge)
end

abstract type FitnessMetric end

struct EdgeFit <: FitnessMetric end
struct AreaFit <: FitnessMetric end

fitness_metric_value(::Val{:edge}) = EdgeFit()
fitness_metric_value(::Val{:area}) = AreaFit()

abstract type BinSelectionMethod end

struct SelectFirstFit <: BinSelectionMethod end
struct SelectBestFit <: BinSelectionMethod end

@inline bin_selection_value(::Val{:first_fit}) = SelectFirstFit()
@inline bin_selection_value(::Val{:best_fit}) = SelectBestFit()
