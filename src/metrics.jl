abstract type SortingMetric end

struct SortByNothing <: SortingMetric end
struct SortByWidth <: SortingMetric end
struct SortByHeight <: SortingMetric end
struct SortByPerimeter <: SortingMetric end
struct SortByArea <: SortingMetric end
struct SortByEdgeDifference <: SortingMetric end
struct SortByAspectRatio <: SortingMetric end
struct SortByShortestEdge <: SortingMetric end
struct SortByLongestEdge <: SortingMetric end

@inline sorting_metric_value(::Val{:none}) = SortByNothing()
@inline sorting_metric_value(::Val{:width}) = SortByWidth()
@inline sorting_metric_value(::Val{:height}) = SortByHeight()
@inline sorting_metric_value(::Val{:perimeter}) = SortByPerimeter()
@inline sorting_metric_value(::Val{:area}) = SortByArea()
@inline sorting_metric_value(::Val{:edge_difference}) = SortByEdgeDifference()
@inline sorting_metric_value(::Val{:aspect_ratio}) = SortByAspectRatio()
@inline sorting_metric_value(::Val{:shortest_edge}) = SortByShortestEdge()
@inline sorting_metric_value(::Val{:longest_edge}) = SortByLongestEdge()

@inline sort_rects(rects, by::F; rev=true) where {F} = sort(rects, by=by, rev=rev)
@inline sort_rects(rects, ::SortByNothing) = rects
@inline sort_rects(rects, ::SortByWidth) = sort_rects(rects, width)
@inline sort_rects(rects, ::SortByHeight) = sort_rects(rects, height)
@inline sort_rects(rects, ::SortByPerimeter) = sort_rects(rects, perimeter)
@inline sort_rects(rects, ::SortByArea) = sort_rects(rects, area)
@inline sort_rects(rects, ::SortByEdgeDifference) = sort_rects(rects, edge_difference, rev=false)
@inline sort_rects(rects, ::SortByAspectRatio) = sort_rects(rects, aspect_ratio, rev=false)

@inline function sort_rects(rects, ::SortByShortestEdge)
    sort_rects(rects, longest_edge)
    sort_rects(rects, shortest_edge)
end

@inline function sort_rects(rects, ::SortByLongestEdge)
    sort_rects(rects, shortest_edge)
    sort_rects(rects, longest_edge)
end

abstract type FitnessMetric end

struct EdgeFit <: FitnessMetric end
struct AreaFit <: FitnessMetric end

@inline fitness_metric_value(::Val{:edge}) = EdgeFit()
@inline fitness_metric_value(::Val{:area}) = AreaFit()
