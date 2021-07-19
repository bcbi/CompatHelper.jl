@testset "get_project_deps" begin
    @testset "no jll" begin
        apply([git_clone_patch, project_toml_patch, cd_patch]) do
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(; token=GitHub.Token("token")),
                "",
                GitHub.Repo(; full_name="foobar"),
            )

            @test length(deps) == 1
        end
    end

    @testset "include_jll" begin
        apply([git_clone_patch, project_toml_patch, cd_patch]) do
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(; token=GitHub.Token("token")),
                "",
                GitHub.Repo(; full_name="foobar");
                include_jll=true,
            )

            @test length(deps) == 2
        end
    end
end

@testset "clone_all_registries" begin
    registry_1_name = "foobar"
    registry_2_name = "bizbaz"

    apply([mktempdir_patch, git_clone_patch]) do
        CompatHelper.clone_all_registries([
            Pkg.RegistrySpec(; name=registry_1_name, url=""),
            Pkg.RegistrySpec(; name=registry_2_name, url=""),
        ]) do resp
            @test length(resp) == 2

            @test contains(resp[1], registry_1_name)
            @test contains(resp[2], registry_2_name)
        end
    end
end

@testset "get_latest_version_from_registries!" begin
    packageA = "PackageA"
    packageB = "PackageB"
    packageC = "PackageC"

    deps = Set{CompatHelper.DepInfo}([
        # No version specified
        CompatHelper.DepInfo(CompatHelper.Package(packageA, UUID(0))),

        # Version is less than what is in registry
        CompatHelper.DepInfo(
            CompatHelper.Package(packageB, UUID(1)); latest_version=VersionNumber(1)
        ),

        # Version is greater than what is in registry
        CompatHelper.DepInfo(
            CompatHelper.Package(packageC, UUID(2)); latest_version=VersionNumber("3")
        ),
    ])
    apply([clone_all_registries_patch, rm_patch]) do
        result = CompatHelper.get_latest_version_from_registries!(
            deps, Vector{Pkg.RegistrySpec}()
        )

        @test length(result) == 3

        for res in result
            if res.package.name == packageA
                @test res.latest_version == VersionNumber("1")
            elseif res.package.name == packageB
                @test res.latest_version == VersionNumber("2")
            elseif res.package.name == packageC
                @test res.latest_version == VersionNumber("3")
            end
        end
    end
end
