using Combinatorics
using Test

import BinPacker: Rect, width, height, perimeter, area, shortest_edge, longest_edge
import BinPacker: edge_difference, aspect_ratio, packing_efficiency
import BinPacker: contains, intersects, Overlap, Adjacent, fitness, EdgeFit, AreaFit
import BinPacker: SortByPerimeter, SortByLongestEdge, SelectFirstFit, SelectBestFit
import BinPacker: Bin, BinOptions, Packer, pack, rect

function check_intersections(bin)
    for (r1, r2) ∈ combinations(bin.rects, 2)
        if intersects(r1, r2)
            println("r1: $r1, r2: $r2")
            return true
        end
    end
    false
end

@testset "Rect" begin
    r = Rect(3, 7, 11, 17)
    @testset "Properties" begin
        @test r.w == 3
        @test r.h == 7
        @test r.x == 11
        @test r.y == 17
        @test r.l == 11
        @test r.r == 14
        @test r.t == 24
        @test r.b == 17
        @test width(r) == 3
        @test height(r) == 7
        @test perimeter(r) == 20
        @test area(r) == 21
        @test shortest_edge(r) == 3
        @test longest_edge(r) == 7
        @test edge_difference(r) == 4
        @test aspect_ratio(r) == 7 // 3
    end
end

@testset "Compare" begin
    r1 = Rect(20, 20, 10, 10)
    r2 = Rect(20, 20, 20, 20)
    r3 = Rect(22, 22, 18, 18)
    r4 = Rect(20, 20, 40, 20)
    r5 = Rect(20, 20, 20, 40)
    r6 = Rect(20, 20, 40, 40)
    r7 = Rect(2, 10, 20, 20)
    @testset "contains" begin
        @test contains(r1, r1)
        @test contains(r2, r2)
        @test contains(r3, r3)
        @test !contains(r1, r2)
        @test !contains(r2, r1)
        @test contains(r3, r2)
        @test !contains(r3, r1)
        @test !contains(r1, r3)
        @test !contains(r2, r3)
    end
    @testset "intersects" begin
        @test intersects(r1, r1, Overlap())
        @test intersects(r2, r2, Overlap())
        @test intersects(r3, r3, Overlap())
        @test intersects(r3, r2, Overlap())
        @test intersects(r2, r3, Overlap())
        @test intersects(r3, r1, Overlap())
        @test intersects(r1, r3, Overlap())
        @test !intersects(r2, r4, Overlap())
        @test !intersects(r4, r2, Overlap())
        @test !intersects(r2, r5, Overlap())
        @test !intersects(r5, r2, Overlap())
        @test !intersects(r2, r6, Overlap())
        @test !intersects(r6, r2, Overlap())
        @test intersects(r2, r4, Adjacent())
        @test intersects(r4, r2, Adjacent())
        @test intersects(r2, r5, Adjacent())
        @test intersects(r5, r2, Adjacent())
        @test intersects(r2, r6, Adjacent())
        @test intersects(r6, r2, Adjacent())
    end
    @testset "fitness" begin
        @test fitness(r2, r3, EdgeFit()) == -2
        @test fitness(r3, r2, EdgeFit()) == 2
        @test fitness(r6, r6, EdgeFit()) == 0
        @test fitness(r6, r7, EdgeFit()) == 18
        @test fitness(r7, r6, EdgeFit()) == -18
        @test fitness(r2, r3, AreaFit()) == -84
        @test fitness(r3, r2, AreaFit()) == 84
        @test fitness(r6, r6, AreaFit()) == 0
        @test fitness(r6, r7, AreaFit()) == 380
        @test fitness(r7, r6, AreaFit()) == -380
    end
end

@testset "Bin" begin
    bo1 = BinOptions()
    bo2 = BinOptions(padding=4, border=8, rotate=true, fit_by=:edge)
    b1 = Bin(2048, 1024, bo1)
    b2 = Bin(1024, 2048, bo2)
    @testset "Properties" begin
        @test b1.width == 2048
        @test b1.height == 1024
        @test b1.options.padding == 0
        @test b1.options.border == 0
        @test b1.free_space |> length == 1
        @test first(b1.free_space).w == 2048
        @test first(b1.free_space).h == 1024
        @test first(b1.free_space).x == 1
        @test first(b1.free_space).y == 1
        @test b1.target isa Rect
        @test b1.rects |> isempty
        @test b1.options.rotate == false
        @test b1.options.fit_by == AreaFit()
        @test packing_efficiency(b1) == 0.0
        @test b2.width == 1024
        @test b2.height == 2048
        @test b2.options.padding == 4
        @test b2.options.border == 8
        @test b2.free_space |> length == 1
        @test first(b2.free_space).w == 1012
        @test first(b2.free_space).h == 2036
        @test first(b2.free_space).x == 9
        @test first(b2.free_space).y == 9
        @test b2.target isa Rect
        @test b2.rects |> isempty
        @test b2.options.rotate == true
        @test b2.options.fit_by == EdgeFit()
        @test packing_efficiency(b2) == 0.0
    end
end

@testset "Packer" begin
    @testset "Properties" begin
        p1 = Packer()
        p2 = Packer(max_size=(1024, 1024), sort_by=:longest_edge, select_by=:best_fit)
        @test p1.bins |> length == 1
        @test p1.sort_by == SortByPerimeter()
        @test p1.select_by == SelectFirstFit()
        @test p2.bins |> length == 1
        @test p2.sort_by == SortByLongestEdge()
        @test p2.select_by == SelectBestFit()
    end
    @testset "pack: default packer, single bin" begin
        for _ ∈ 1:100
            p = Packer(max_size=(1024, 1024))
            b = p.bins[1]
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:250]
            pack(p, rects)
            bin_rect = rect(b)
            @test packing_efficiency(b) > 0
            @test b.rects |> length == 250
            @test check_intersections(b) == false
            @test all(x -> contains(bin_rect, x), b.rects)
        end
    end
    @testset "pack: default packer, single bin with padding" begin
        for _ ∈ 1:100
            p = Packer(max_size=(1024, 1024), padding=4)
            b = p.bins[1]
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:250]
            pack(p, rects)
            bin_rect = rect(b)
            @test packing_efficiency(b) > 0
            @test b.rects |> length == 250
            @test check_intersections(b) == false
            @test all(x -> contains(bin_rect, x), b.rects)
        end
    end
    @testset "pack: default packer, single bin with border" begin
        for _ ∈ 1:100
            p = Packer(max_size=(1024, 1024), border=8)
            bin = p.bins[1]
            b = bin.options.border
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:250]
            pack(p, rects)
            @test packing_efficiency(bin) > 0
            @test bin.rects |> length == 250
            @test check_intersections(bin) == false
            @test all(x -> contains(rect(bin), x), bin.rects)
            @test all(x -> !intersects(Rect(b, bin.height, 1, 1), x), bin.rects)
            @test all(x -> !intersects(Rect(bin.width, b, 1, 1), x), bin.rects)
            @test any(x -> intersects(Rect(b + 1, bin.height, 1, 1), x), bin.rects)
            @test any(x -> intersects(Rect(bin.width, b + 1, 1, 1), x), bin.rects)
        end
    end
    @testset "pack: default packer, auto-binning enabled with border" begin
        for _ ∈ 1:100
            p = Packer(max_size=(512, 512), border=4, auto_bin=true)
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:200]
            pack(p, rects)
            for bin ∈ p.bins
                b = bin.options.border
                w, h = bin.width, bin.height
                @test bin.rects |> length > 0
                @test packing_efficiency(bin) > 0
                @test check_intersections(bin) == false
                @test all(x -> contains(rect(bin), x), bin.rects)
                @test all(x -> !intersects(Rect(b, h, 1, 1), x), bin.rects)
                @test all(x -> !intersects(Rect(w, b, 1, 1), x), bin.rects)
                @test any(x -> intersects(Rect(b + 1, h, 1, 1), x), bin.rects)
                @test any(x -> intersects(Rect(w, b + 1, 1, 1), x), bin.rects)
            end
        end
    end
    @testset "pack: first-fit packer, auto-binning enabled" begin
        for _ ∈ 1:100
            p = Packer(max_size=(512, 512), select_by=:first_fit, padding=1, auto_bin=true)
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:200]
            pack(p, rects)
            for bin ∈ p.bins
                @test bin.rects |> length > 0
                @test packing_efficiency(bin) > 0
                @test check_intersections(bin) == false
                @test all(x -> contains(rect(bin), x), bin.rects)
            end
        end
    end
    @testset "pack: first-fit packer, auto-binning enabled with padding" begin
        for _ ∈ 1:100
            p = Packer(max_size=(512, 512), select_by=:first_fit, padding=1, auto_bin=true)
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:200]
            pack(p, rects)
            for bin ∈ p.bins
                @test bin.rects |> length > 0
                @test packing_efficiency(bin) > 0
                @test check_intersections(bin) == false
                @test all(x -> contains(rect(bin), x), bin.rects)
            end
        end
    end
    @testset "pack: best-fit packer, auto-binning enabled" begin
        for _ ∈ 1:100
            p = Packer(max_size=(512, 512), select_by=:best_fit, auto_bin=true)
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:200]
            pack(p, rects)
            for bin ∈ p.bins
                @test bin.rects |> length > 0
                @test packing_efficiency(bin) > 0
                @test check_intersections(bin) == false
                @test all(x -> contains(rect(bin), x), bin.rects)
            end
        end
    end
    @testset "pack: best-fit packer, auto-binning enabled with padding" begin
        for _ ∈ 1:100
            p = Packer(max_size=(512, 512), select_by=:best_fit, padding=2, auto_bin=true)
            rects = [Rect(rand(2:80), rand(2:80)) for _ ∈ 1:200]
            pack(p, rects)
            for bin ∈ p.bins
                @test bin.rects |> length > 0
                @test packing_efficiency(bin) > 0
                @test check_intersections(bin) == false
                @test all(x -> contains(rect(bin), x), bin.rects)
            end
        end
    end
end
