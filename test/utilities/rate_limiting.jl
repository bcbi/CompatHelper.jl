@testset "api_retry" begin
    idx = 1
    fails = [true, false]

    result = CompatHelper.api_retry() do
        retval = fails[idx]
        idx += 1

        if retval
            throw(Exception())
        else
            return idx
        end
    end

    # We ran through the loop twice
    @test result == 3
end
