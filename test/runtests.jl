using Aqua
using Base64
using CompatHelper
using Dates
using GitForge
using GitForge: GitForge, GitHub, GitLab
using Mocking
using Pkg
using Random
using SHA
using Test
using TimeZones
using TOML
using UUIDs

Mocking.activate()

Aqua.test_all(CompatHelper; ambiguities=false)

@testset "`version =` line in the workflow file" begin
    root_directory = dirname(dirname(@__FILE__))
    project_file = joinpath(root_directory, "Project.toml")
    version = Base.VersionNumber(TOML.parsefile(project_file)["version"])
    major_version = version.major
    @test major_version >= 1
    workflow_dir = joinpath(root_directory, ".github", "workflows")
    workflow_filename = joinpath(workflow_dir, "CompatHelper.yml")
    workflow_filecontents = read(workflow_filename, String)
    @test occursin(Regex("\\sversion = \"$(major_version)\"\n"), workflow_filecontents)
    @test length(findall(r"version[\s]*?=", workflow_filecontents)) == 1
end
include("patches.jl")

@testset "CompatHelper.jl" begin
    include(joinpath("utilities", "ci.jl"))
    include(joinpath("utilities", "git.jl"))
    include(joinpath("utilities", "new_versions.jl"))
    include(joinpath("utilities", "ssh.jl"))
    include(joinpath("utilities", "types.jl"))
    include(joinpath("utilities", "utilities.jl"))
    include(joinpath("utilities", "rate_limiting.jl"))
    include(joinpath("utilities", "timestamps.jl"))

    include("dependencies.jl")
    include("exceptions.jl")
    include("pull_requests.jl")
    include("main.jl")

    COMPATHELPER_RUN_INTEGRATION_TESTS = get(ENV, "COMPATHELPER_RUN_INTEGRATION_TESTS", "")
    if COMPATHELPER_RUN_INTEGRATION_TESTS == "true"
        @testset "Integration Tests" begin
            @info "Running Integration Tests"
            include(joinpath("utilities", "integration_tests.jl"))
            include("integration_tests.jl")
        end
    end
end
