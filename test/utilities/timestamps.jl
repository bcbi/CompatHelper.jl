@testset "now_localzone" begin
    @test CompatHelper.now_localzone() isa TimeZones.ZonedDateTime
end

@testset "utc_to_string" begin
    zdt = ZonedDateTime(DateTime(2021, 1, 2, 3, 4, 5, 6), tz"America/Winnipeg")
    @test CompatHelper.utc_to_string(zdt) == "2021-01-02-09-04-05-006"
end
