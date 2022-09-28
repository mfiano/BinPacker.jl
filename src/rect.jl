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

@inline Base.eachindex(rect::Rect) = Iterators.product(rect.l:rect.r-1, rect.b:rect.t-1)

@inline _make_rect(w, h, x, y) = Rect(w, h, x, y, false)
@inline make_rect(w, h) = _make_rect(w, h, 1, 1)

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

@inline width(rect) = rect.w
@inline height(rect) = rect.h
@inline perimeter(rect) = 2rect.w + 2rect.h
@inline area(rect) = rect.w * rect.h
@inline shortest_edge(rect) = min(rect.w, rect.h)
@inline longest_edge(rect) = max(rect.w, rect.h)
@inline edge_difference(rect) = longest_edge(rect) - shortest_edge(rect)
@inline aspect_ratio(rect) = longest_edge(rect) ÷ shortest_edge(rect)
