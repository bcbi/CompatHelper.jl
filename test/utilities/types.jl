@testset "Package Base.in" begin
    p = CompatHelper.Package("Foobar", UUID(1))
    ce = CompatHelper.DepInfo(p)

    @testset "Exists" begin
        s = Set([ce])

        @test p in s
    end

    @testset "DNE" begin
        p2 = CompatHelper.Package("BizBaz", UUID(0))
        @test !(p2 in Set([ce]))
    end
end
