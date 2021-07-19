abstract type CIService end

struct GitHubActions <: CIService
    username::String
    email::String

    function GitHubActions(
        username="github-actions[bot]",
        email="41898282+github-actions[bot]@users.noreply.github.com",
    )
        return new(username, email)
    end
end

struct GitLabCI <: CIService
    username::String
    email::String

    function GitLabCI(username="gitlab-ci[bot]", email="gitlab-ci[bot]@gitlab.com")
        return new(username, email)
    end
end

api_hostname(::GitHubActions) = "https://api.github.com"
api_hostname(::GitLabCI) = "https://gitlab.com/api/v4"

clone_hostname(::GitHubActions) = "github.com"
clone_hostname(::GitLabCI) = "gitlab.com"

ci_repository(::GitHubActions, env::AbstractDict=ENV) = env["GITHUB_REPOSITORY"]
ci_repository(::GitLabCI, env::AbstractDict=ENV) = env["CI_PROJECT_PATH"]

ci_token(::GitHubActions, env::AbstractDict=ENV) = env["GITHUB_TOKEN"]
ci_token(::GitLabCI, env::AbstractDict=ENV) = env["GITLAB_TOKEN"]

function get_api_and_repo(ci::GitHubActions, hostname_for_api::AbstractString; env=ENV)
    token = GitHub.Token(ci_token(ci, env))
    api = GitHub.GitHubAPI(; token=token, url=hostname_for_api)
    repo, _ = @mock GitForge.get_repo(api, ci_repository(ci, env))
    return api, repo
end

function get_api_and_repo(ci::GitLabCI, hostname_for_api::AbstractString; env=ENV)
    token = GitLab.PersonalAccessToken(ci_token(ci, env))
    api = GitLab.GitLabAPI(; token=token, url=hostname_for_api)
    repo, _ = @mock GitForge.get_repo(api, ci_repository(ci, env))
    return api, repo
end

function get_api_and_repo(ci::Any, hostname_for_api::AbstractString)
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
