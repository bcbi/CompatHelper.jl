gh_unique_patch = @patch function Base.unique(
    ::GitForge.Paginator{GitForge.GitHub.PullRequest}
)
    return [GitHub.PullRequest(; id=1), GitHub.PullRequest(; id=2)]
end
gl_unique_patch = @patch function Base.unique(
    ::GitForge.Paginator{GitForge.GitLab.MergeRequest}
)
    return [GitLab.MergeRequest(; id=1), GitLab.MergeRequest(; id=2)]
end
project_toml_patch = @patch function Base.joinpath(p::AbstractString...)
    return joinpath(@__DIR__, "deps", "Project.toml")
end
git_clone_patch = @patch function CompatHelper.git_clone(
    url::AbstractString, p::AbstractString
)
    return nothing
end
git_push_patch = @patch function CompatHelper.git_push(
    ::AbstractString, ::AbstractString, ::Union{AbstractString,Nothing}; kwargs...
)
    return nothing
end
git_gmb_patch = @patch CompatHelper.git_get_master_branch(master_branch) = nothing
git_checkout_patch = @patch CompatHelper.git_checkout(branch) = nothing
mktempdir_patch = @patch Base.mktempdir(; cleanup::Bool=true) = Random.randstring()
rm_patch = @patch Base.rm(tmp_dir; force=true, recursive=true) = nothing
cd_patch = @patch Base.cd(f, path) = nothing

clone_all_registries_patch = @patch function CompatHelper.clone_all_registries(
    f::Function, registry_list::Vector{Pkg.RegistrySpec}
)
    return f([
        joinpath(@__DIR__, "deps", "registry_1"), joinpath(@__DIR__, "deps", "registry_2")
    ])
end

gh_pr_patch = @patch function GitForge.create_pull_request(
    ::GitHub.GitHubAPI, owner::AbstractString, repo::AbstractString; kwargs...
)
    return GitHub.PullRequest(), nothing
end

gl_pr_patch = @patch function GitForge.create_pull_request(
    ::GitLab.GitLabAPI, owner::AbstractString, repo::AbstractString; kwargs...
)
    return GitLab.MergeRequest(), nothing
end

decode_pkey_patch = @patch function CompatHelper.decode_ssh_private_key(::AbstractString)
    return "pkey_info"
end

pr_titles_mock = @patch function CompatHelper.get_pr_titles(
    ::GitForge.Forge, ::GitHub.Repo, ::String
)
    return [
        "CompatHelper: bump compat for PackageA to\n    1 ,  (keep existing compat)", "foo"
    ]
end

function make_clone_https_patch(dir::AbstractString)
    return @patch function CompatHelper.get_url_with_auth(
        ::GitForge.Forge, ::CIService, ::Union{GitHub.Repo,GitLab.Project}
    )
        return dir
    end
end

function make_clone_ssh_patch(dir::AbstractString)
    return @patch function CompatHelper.get_url_for_ssh(
        ::GitForge.Forge, ::CIService, ::Union{GitHub.Repo,GitLab.Project}
    )
        return dir
    end
end

gh_gpr_patch = @patch function CompatHelper.get_pull_requests(
    api::GitHub.GitHubAPI, repo::GitHub.Repo, state::String
)
    origin_repo = GitHub.Repo(; id=1)
    fork_repo = GitHub.Repo(; id=2)

    pr_from_origin = GitHub.PullRequest(;
        head=GitHub.Head(; repo=origin_repo),
        user=GitHub.User(; login="foobar"),
        title="title",
    )
    pr_from_origin_2 = GitHub.PullRequest(;
        head=GitHub.Head(; repo=origin_repo), user=GitHub.User(; login="bizbaz")
    )
    pr_from_fork = GitHub.PullRequest(; head=GitHub.Head(; repo=fork_repo))

    return [(pr_from_origin, nothing), (pr_from_origin_2, nothing), (pr_from_fork, nothing)]
end

gl_gpr_patch = @patch function CompatHelper.get_pull_requests(
    api::GitLab.GitLabAPI, repo::GitLab.Project, state::String
)
    origin_repo = GitLab.Project(; id=1)

    pr_from_origin = GitLab.MergeRequest(;
        project_id=1, author=GitLab.User(; username="foobar"), title="title"
    )
    pr_from_origin_2 = GitLab.MergeRequest(;
        project_id=1, author=GitLab.User(; username="bizbaz")
    )
    pr_from_fork = GitLab.MergeRequest(; project_id=2)

    return [(pr_from_origin, nothing), (pr_from_origin_2, nothing), (pr_from_fork, nothing)]
end

function get_prs_patch(prs)
    return @patch function CompatHelper.get_pull_requests(
        ::GitForge.Forge, ::Union{GitHub.Repo,GitLab.Project}, ::String
    )
        return [(pr, nothing) for pr in prs]
    end
end

gh_get_repo_patch = @patch function GitForge.get_repo(::GitForge.Forge, ::AbstractString)
    return GitHub.Repo(), nothing
end

gl_get_repo_patch = @patch function GitForge.get_repo(::GitForge.Forge, ::AbstractString)
    return GitLab.Project(), nothing
end

gh_comment_patch = @patch function GitForge.create_pull_request_comment(
    ::GitHub.GitHubAPI, ::AbstractString, ::AbstractString, ::Integer; kwargs...
)
    return GitHub.Comment(), nothing
end

gl_comment_patch = @patch function GitForge.create_pull_request_comment(
    ::GitLab.GitLabAPI, ::Integer, ::Integer; kwargs...
)
    return GitLab.Note(), nothing
end

gl_unsub_patch = @patch function GitForge.unsubscribe_from_pull_request(
    ::GitLab.GitLabAPI, ::Integer, ::Integer
)
    return GitLab.MergeRequest(), nothing
end
