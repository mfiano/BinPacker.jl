module BinPacker

using Random: shuffle!

export add_bin!, make_bin, make_packer, make_rect, pack

include("metrics.jl")
include("rect.jl")
include("compare.jl")
include("bin.jl")
include("packer.jl")

end
