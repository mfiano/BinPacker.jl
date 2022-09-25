abstract type IntersectionMethod end

struct Overlap <: IntersectionMethod end
struct Adjacent <: IntersectionMethod end

@inline contains(r1::Rect, r2::Rect) = r1.r ≥ r2.r ≥ r2.l ≥ r1.l && r1.t ≥ r2.t ≥ r2.b ≥ r1.b
@inline intersects(r1, r2, ::Overlap) = r1.l < r2.r && r1.r > r2.l && r1.b < r2.t && r1.t > r2.b
@inline intersects(r1, r2, ::Adjacent) = r1.l ≤ r2.r && r1.r ≥ r2.l && r1.b ≤ r2.t && r1.t ≥ r2.b
@inline intersects(r1, r2) = intersects(r1, r2, Overlap())
@inline fitness(r1, r2, ::EdgeFit) = shortest_edge(r1) - shortest_edge(r2)
@inline fitness(r1, r2, ::AreaFit) = area(r1) - area(r2)
