@testset "$(exec)" for exec in [
    CompatHelper.UnableToParseSSHKey, CompatHelper.UnableToDetectCIService
]
    io = IOBuffer()
    message = "foobar"
    show(io, exec(message))

    @test contains(String(io.data), message)
end
