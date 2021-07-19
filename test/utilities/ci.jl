@testset "auto_detect_ci_service" begin
    @testset "GitHub: env var present" begin
        withenv("GITHUB_REPOSITORY" => "true") do
            expected = CompatHelper.GitHubActions()

            @test CompatHelper.auto_detect_ci_service() == expected
        end
    end

    @testset "GitLab: env var present" begin
        withenv("GITLAB_CI" => "true", "GITHUB_REPOSITORY" => "false") do
            delete!(ENV, "GITHUB_REPOSITORY")
            expected = CompatHelper.GitLabCI()

            @test CompatHelper.auto_detect_ci_service() == expected
        end
    end

    @testset "env var dne" begin
        withenv("GITHUB_REPOSITORY" => "foobar", "GITLAB_CI" => "foobar") do
            delete!(ENV, "GITHUB_REPOSITORY")
            delete!(ENV, "GITLAB_CI")
            @test_throws CompatHelper.UnableToDetectCIService CompatHelper.auto_detect_ci_service()
        end
    end
end

@testset "$(func)" for func in [CompatHelper.ci_repository, CompatHelper.ci_token]
    value = "value"
    ci = CompatHelper.GitHubActions()

    @testset "exists" begin
        withenv("GITHUB_REPOSITORY" => value, "GITHUB_TOKEN" => value) do
            @test func(ci) == value
        end
    end

    @testset "dne" begin
        withenv("GITHUB_REPOSITORY" => value, "GITHUB_TOKEN" => value) do
            delete!(ENV, "GITHUB_REPOSITORY")
            delete!(ENV, "GITHUB_TOKEN")

            @test_throws KeyError func(ci)
        end
    end
end

@testset "$(func)" for func in [CompatHelper.ci_repository, CompatHelper.ci_token]
    value = "value"
    ci = CompatHelper.GitLabCI()

    @testset "exists" begin
        withenv("CI_PROJECT_PATH" => value, "GITLAB_TOKEN" => value) do
            @test func(ci) == value
        end
    end

    @testset "dne" begin
        withenv("CI_PROJECT_PATH" => value, "GITLAB_TOKEN" => value) do
            delete!(ENV, "CI_PROJECT_PATH")
            delete!(ENV, "GITLAB_TOKEN")

            @test_throws KeyError func(ci)
        end
    end
end
