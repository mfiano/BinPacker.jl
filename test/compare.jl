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
