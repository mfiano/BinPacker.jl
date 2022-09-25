using BinPacker
using Documenter

DocMeta.setdocmeta!(BinPacker, :DocTestSetup, :(using BinPacker); recursive=true)

makedocs(;
    modules=[BinPacker],
    authors="Michael Fiano <mail@mfiano.net> and contributors",
    repo="https://github.com/mfiano/BinPacker.jl/blob/{commit}{path}#{line}",
    sitename="BinPacker.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://mfiano.github.io/BinPacker.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mfiano/BinPacker.jl",
    devbranch="main",
)
