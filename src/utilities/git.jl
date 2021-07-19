const COMPATHELPER_GIT_COMMITTER_NAME = "CompatHelper Julia"
const COMPATHELPER_GIT_COMMITTER_EMAIL = "compathelper_noreply@julialang.org"

function get_git_name_and_email(; env=ENV)
    name = if haskey(env, "GIT_COMMITTER_NAME")
        env["GIT_COMMITTER_NAME"]
    else
        COMPATHELPER_GIT_COMMITTER_NAME
    end

    email = if haskey(env, "GIT_COMMITTER_EMAIL")
        env["GIT_COMMITTER_EMAIL"]
    else
        COMPATHELPER_GIT_COMMITTER_EMAIL
    end

    return name, email
end

git_checkout(branch::AbstractString) = run(`git checkout $branch`)

function git_add()
    run(`git add -A .`)

    return nothing
end

function git_push(
    remote::AbstractString,
    branch::AbstractString,
    pkey_filename::Union{AbstractString,Nothing}=nothing;
    force=false,
    env=ENV,
)
    force_flag = force ? ["-f"] : []
    name, email = get_git_name_and_email(; env=env)

    withenv(
        "GIT_SSH_COMMAND" => isnothing(pkey_filename) ? "ssh" : "ssh -i $pkey_filename"
    ) do
        run(
            `git -c user.name="$name" -c user.email="$email" -c committer.name="$name" -c committer.email="$email" push $force_flag $remote $branch`,
        )
    end
    return nothing
end

function git_commit(message::AbstractString=""; env=ENV)
    name, email = get_git_name_and_email(; env=env)
    cmd = `git -c user.name="$name" -c user.email="$email" commit -m $message`

    result = try
        p = pipeline(cmd; stdout=stdout, stderr=stderr)
        success(p)
    catch
        false
    end

    return result
end

function git_branch(branch::AbstractString; checkout=false)
    run(`git branch $branch`)
    checkout && git_checkout(branch)

    return nothing
end

function git_clone(
    url::AbstractString,
    local_path::AbstractString,
    pkey_filename::Union{AbstractString,Nothing}=nothing,
)
    withenv(
        "GIT_SSH_COMMAND" => isnothing(pkey_filename) ? "ssh" : "ssh -i $pkey_filename"
    ) do
        @mock run(`git clone $url $local_path`)
    end

    return nothing
end

function git_get_master_branch(master_branch::DefaultBranch)
    return string(strip(read(`git rev-parse --abbrev-ref HEAD`, String)))
end

function git_get_master_branch(master_branch::AbstractString)
    return master_branch
end
