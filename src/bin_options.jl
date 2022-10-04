struct BinOptions{F <: FitnessAlgorithm}
    max_size::NTuple{2, Int}
    padding::Int
    border::Int
    rotate::Bool
    resize_by::NTuple{2, Int}
    pow2::Bool
    square::Bool
    fit_by::F
end

function BinOptions(max_size, padding, border, rotate, resize_by, pow2, square, fit_by::Symbol)
    fit_by = fitness_algorithm_value(Val(fit_by))
    BinOptions(max_size, padding, border, rotate, resize_by, pow2, square, fit_by)
end

function BinOptions(;
    max_size=(4096, 4096),
    padding=0,
    border=0,
    rotate=false,
    resize_by=(1, 1),
    pow2=false,
    square=false,
    fit_by=:area
)
    BinOptions(max_size, padding, border, rotate, resize_by, pow2, square, fit_by)
end
