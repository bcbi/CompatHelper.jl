abstract type CIService end

struct GitHubActions <: CIService
    username::String
    email::String
    api_hostname::String
    clone_hostname::String

    function GitHubActions(;
        username="github-actions[bot]",
        email="41898282+github-actions[bot]@users.noreply.github.com",
        api_hostname="https://api.github.com",
        clone_hostname="github.com"
    )
        return new(username, email, api_hostname, clone_hostname)
    end
end

struct GitLabCI <: CIService
    username::String
    email::String
    api_hostname::String
    clone_hostname::String

    function GitLabCI(;
        username="gitlab-ci[bot]",
        email="gitlab-ci[bot]@gitlab.com",
        api_hostname="https://gitlab.com/api/v4",
        clone_hostname="gitlab.com"
    )
        return new(username, email, api_hostname, clone_hostname)
    end
end

ci_repository(::GitHubActions, env::AbstractDict=ENV) = env["GITHUB_REPOSITORY"]
ci_repository(::GitLabCI, env::AbstractDict=ENV) = env["CI_PROJECT_PATH"]

ci_token(::GitHubActions, env::AbstractDict=ENV) = env["GITHUB_TOKEN"]
ci_token(::GitLabCI, env::AbstractDict=ENV) = env["GITLAB_TOKEN"]

function get_api_and_repo(ci::GitHubActions; env=ENV)
    token = GitHub.Token(ci_token(ci, env))
    api = GitHub.GitHubAPI(; token=token, url=ci.api_hostname)
    repo, _ = @mock GitForge.get_repo(api, ci_repository(ci, env))
    return api, repo
end

function get_api_and_repo(ci::GitLabCI; env=ENV)
    token = GitLab.PersonalAccessToken(ci_token(ci, env))
    api = GitLab.GitLabAPI(; token=token, url=ci.api_hostname)
    repo, _ = @mock GitForge.get_repo(api, ci_repository(ci, env))
    return api, repo
end

function get_api_and_repo(ci::Any)
    err = "Unknown CI Config: $(typeof(ci))"
    @error(err)
    return throw(ErrorException(err))
end

function auto_detect_ci_service(; env::AbstractDict=ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    elseif haskey(env, "GITLAB_CI")
        return GitLabCI()
    else
        throw(UnableToDetectCIService("Could not detect CI service"))
    end
end
