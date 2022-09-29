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
