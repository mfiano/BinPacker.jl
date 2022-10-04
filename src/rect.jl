mutable struct Rect
    id::Int
    w::Int32
    h::Int32
    x::Int32
    y::Int32
    rotated::Bool
end

function Base.show(io::IO, obj::Rect)
    (; w, h, x, y) = obj
    type = obj |> typeof
    print(io, "$w×$h $type($x, $y)")
end

@inline Rect(w, h, x=1, y=1, id=0) = Rect(id, w, h, x, y, false)

@inline function Base.getproperty(rect::Rect, name::Symbol)
    if name ≡ :l
        getfield(rect, :x)
    elseif name ≡ :r
        getfield(rect, :w) + getfield(rect, :x)
    elseif name ≡ :t
        getfield(rect, :h) + getfield(rect, :y)
    elseif name ≡ :b
        getfield(rect, :y)
    else
        getfield(rect, name)
    end
end

@inline Base.eachindex(rect::Rect) = Iterators.product(rect.l:rect.r-1, rect.b:rect.t-1)

@inline width(rect::Rect) = rect.w
@inline height(rect::Rect) = rect.h
@inline perimeter(rect::Rect) = 2rect.w + 2rect.h
@inline area(rect::Rect) = rect.w * rect.h
@inline shortest_edge(rect::Rect) = min(rect.w, rect.h)
@inline longest_edge(rect::Rect) = max(rect.w, rect.h)
@inline edge_difference(rect::Rect) = longest_edge(rect) - shortest_edge(rect)
@inline aspect_ratio(rect::Rect) = longest_edge(rect) // shortest_edge(rect)
