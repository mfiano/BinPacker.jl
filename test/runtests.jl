using Combinatorics
using Test

import BinPacker: Rect, width, height, perimeter, area, shortest_edge, longest_edge
import BinPacker: edge_difference, aspect_ratio
import BinPacker: contains, intersects, Overlap, Adjacent, fitness, EdgeFit, AreaFit

include("rect.jl")
include("compare.jl")
