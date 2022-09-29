mutable struct Rect
    w::Int32
    h::Int32
    x::Int32
    y::Int32
    rotated::Bool
end

function Base.show(io::IO, obj::Rect)
    (; w, h, x, y) = obj
    type = obj |> typeof
    print(io, "$w×$h $type(:x => $x, :y => $y)")
end

@inline Rect(w, h, x=1, y=1) = Rect(w, h, x, y, false)

@inline function Base.getproperty(r::Rect, name::Symbol)
    if name ≡ :l
        getfield(r, :x)
    elseif name ≡ :r
        getfield(r, :w) + getfield(r, :x)
    elseif name ≡ :t
        getfield(r, :h) + getfield(r, :y)
    elseif name ≡ :b
        getfield(r, :y)
    else
        getfield(r, name)
    end
end

@inline Base.eachindex(r::Rect) = Iterators.product(r.l:r.r-1, r.b:r.t-1)

@inline width(r::Rect) = r.w
@inline height(r::Rect) = r.h
@inline perimeter(r::Rect) = 2r.w + 2r.h
@inline area(r::Rect) = r.w * r.h
@inline shortest_edge(r::Rect) = min(r.w, r.h)
@inline longest_edge(r::Rect) = max(r.w, r.h)
@inline edge_difference(r::Rect) = longest_edge(r) - shortest_edge(r)
@inline aspect_ratio(r::Rect) = longest_edge(r) // shortest_edge(r)
