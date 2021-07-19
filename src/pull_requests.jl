function get_pull_requests(
    api::GitHub.GitHubAPI,
    repo::GitHub.Repo,
    state::String;
    per_page::Integer=100,
    page_limit::Integer=100,
)
    repo_name = repo.name
    repo_owner = repo.owner.login
    paginated_prs = GitForge.paginate(
        GitHub.get_pull_requests,
        api,
        repo_owner,
        repo_name;
        state=state,
        per_page=per_page,
        page_limit=page_limit,
    )

    return @mock unique(paginated_prs)
end

function get_pull_requests(
    api::GitLab.GitLabAPI,
    project::GitLab.Project,
    state::String;
    per_page::Integer=100,
    page::Integer=1,
)
    project_id = project.id
    paginated_prs = GitForge.paginate(
        GitLab.get_pull_requests, api, project_id; state=state, per_page=per_page, page=page
    )

    return @mock unique(paginated_prs)
end

not_pr_fork(repo::GitHub.Repo, pr::GitHub.PullRequest) = repo == pr.head.repo
not_pr_fork(repo::GitLab.Project, pr::GitLab.MergeRequest) = repo.id == pr.project_id

my_prs(username::String, pr::GitHub.PullRequest) = lower(pr.user.login) == lower(username)
function my_prs(username::String, pr::GitLab.MergeRequest)
    return lower(pr.author.username) == lower(username)
end

function get_pr_titles(
    forge::Forge, repo::Union{GitHub.Repo,GitLab.Project}, username::AbstractString
)
    state = repo isa GitHub.Repo ? "open" : "opened"
    all_open_prs = @mock get_pull_requests(forge, repo, state)
    return [
        convert(String, strip(pr.title)) for
        (pr, _) in all_open_prs if not_pr_fork(repo, pr) && my_prs(username, pr)
    ]
end
