@testset "GitLab.MergeRequest equality" begin
    a = GitLab.MergeRequest(; id=1)
    b = GitLab.MergeRequest(; id=1)

    @test a == b
    @test isequal(a, b)
end

@testset "get_pull_requests" begin
    @testset "GitHub" begin
        api = GitForge.GitHub.GitHubAPI()
        repo = GitHub.Repo(; name="Foo", owner=GitHub.User(; login="Bar"))

        apply(gh_unique_patch) do
            prs = CompatHelper.get_pull_requests(
                api, repo, "open"; per_page=10, page_limit=1
            )
            @test !isempty(prs)
        end
    end

    @testset "GitLab" begin
        api = GitForge.GitLab.GitLabAPI()
        repo = GitLab.Project(; id=1)

        apply(gl_unique_patch) do
            prs = CompatHelper.get_pull_requests(api, repo, "opened")
            @test !isempty(prs)
        end
    end
end

@testset "get_pr_titles" begin
    username = "foo"

    @testset "no forks" begin
        @testset "GitHub" begin
            origin_repo = GitHub.Repo(; id=1)
            fork_repo = GitHub.Repo(; id=2)

            pr_from_origin = GitHub.PullRequest(;
                head=GitHub.Head(; repo=origin_repo),
                user=GitHub.User(; login=username),
                title="PR A",
            )
            pr_from_fork = GitHub.PullRequest(;
                head=GitHub.Head(; repo=fork_repo),
                user=GitHub.User(; login=username),
                title="PR B",
            )

            apply(get_prs_patch([pr_from_origin, pr_from_fork])) do
                result = CompatHelper.get_pr_titles(
                    GitHub.GitHubAPI(), origin_repo, username
                )

                @test length(result) == 1
                @test pr_from_origin.title in result
                @test !(pr_from_fork.title in result)
            end
        end

        @testset "GitLab" begin
            origin_repo = GitLab.Project(; id=1)
            fork_repo = GitLab.Project(; id=2)

            pr_from_origin = GitLab.MergeRequest(;
                id=1, project_id=1, author=GitLab.User(; username=username), title="PR A"
            )
            pr_from_fork = GitLab.MergeRequest(;
                id=1, project_id=2, author=GitLab.User(; username=username), title="PR B"
            )

            apply(get_prs_patch([pr_from_origin, pr_from_fork])) do
                result = CompatHelper.get_pr_titles(
                    GitLab.GitLabAPI(), origin_repo, username
                )

                @test length(result) == 1
                @test pr_from_origin.title in result
                @test !(pr_from_fork.title in result)
            end
        end
    end

    @testset "only my prs" begin
        @testset "GitHub" begin
            origin_repo = GitHub.Repo(; id=1)

            pr_from_me = GitHub.PullRequest(;
                head=GitHub.Head(; repo=origin_repo),
                user=GitHub.User(; login=username),
                title="PR A",
            )
            pr_from_other = GitHub.PullRequest(;
                head=GitHub.Head(; repo=origin_repo),
                user=GitHub.User(; login="bizbaz"),
                title="PR B",
            )

            apply(get_prs_patch([pr_from_me, pr_from_other])) do
                result = CompatHelper.get_pr_titles(
                    GitHub.GitHubAPI(), origin_repo, username
                )

                @test length(result) == 1
                @test pr_from_me.title in result
                @test !(pr_from_other.title in result)
            end
        end

        @testset "GitLab" begin
            origin_repo = GitLab.Project(; id=1)

            pr_from_me = GitLab.MergeRequest(;
                id=1, project_id=1, author=GitLab.User(; username=username), title="PR A"
            )
            pr_from_other = GitLab.MergeRequest(;
                id=2, project_id=1, author=GitLab.User(; username="bizbaz"), title="PR B"
            )

            apply(get_prs_patch([pr_from_me, pr_from_other])) do
                result = CompatHelper.get_pr_titles(
                    GitLab.GitLabAPI(), origin_repo, username
                )

                @test length(result) == 1
                @test pr_from_me.title in result
                @test !(pr_from_other.title in result)
            end
        end
    end

    @testset "no forks and only my prs" begin
        @testset "GitHub" begin
            api = GitForge.GitHub.GitHubAPI()
            repo = GitHub.Repo(; id=1)

            apply(gh_gpr_patch) do
                prs = CompatHelper.get_pr_titles(api, repo, "foobar")
                @test !isempty(prs)
                @test prs[1] == "title"
            end
        end

        @testset "GitLab" begin
            api = GitForge.GitLab.GitLabAPI()
            repo = GitLab.Project(; id=1)

            apply(gl_gpr_patch) do
                prs = CompatHelper.get_pr_titles(api, repo, "foobar")
                @test !isempty(prs)
                @test prs[1] == "title"
            end
        end
    end
end
