@testset "is_raw_ssh_private_key" begin
    content = "- BEGIN END PRIVATE KEY"

    @test CompatHelper.is_raw_ssh_private_key(content)
end

@testset "decode_ssh_private_key" begin
    expected = "- BEGIN END PRIVATE KEY"

    @testset "raw key" begin
        @test CompatHelper.decode_ssh_private_key(expected) == expected
    end

    @testset "base64 encoded" begin
        encoded = Base64.base64encode(expected)

        @test CompatHelper.decode_ssh_private_key(encoded) == expected
    end

    @testset "non-base64 encoded" begin
        encoded = bytes2hex(SHA.sha256(expected))

        @test_throws CompatHelper.UnableToParseSSHKey CompatHelper.decode_ssh_private_key(
            encoded
        )
    end
end
