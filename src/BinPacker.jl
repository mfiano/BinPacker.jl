module BinPacker

using Random: shuffle!

export add_bin!, Bin, Packer, Rect, pack

include("algorithm_types.jl")
include("rect.jl")
include("compare.jl")
include("bin.jl")
include("packer.jl")

end
