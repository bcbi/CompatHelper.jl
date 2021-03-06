const timestamp_regex = r"\/(\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d-\d\d\d)[\/\-]"

function delete_old_pull_request_branches(AUTOMERGE_INTEGRATION_TEST_REPO, older_than)
    with_cloned_repo(AUTOMERGE_INTEGRATION_TEST_REPO) do git_repo_dir
        cd(git_repo_dir) do
            all_origin_branches = list_all_origin_branches(git_repo_dir)::Vector{String}
            branches_to_delete = String[]
            for branch_name in all_origin_branches
                if occursin(timestamp_regex, branch_name)
                    commit = strip(read(`git rev-parse origin/$(branch_name)`, String))
                    age = get_age_of_commit(commit)
                    if age >= older_than
                        push!(branches_to_delete, branch_name)
                    end
                end
            end
            unique!(branches_to_delete)
            m = 50
            for _ in 1:(ceil(Int, length(branches_to_delete)/m) + 1)
                k = min(m, length(branches_to_delete))
                current_branches = branches_to_delete[1:k]
                branches_to_delete = branches_to_delete[(k+1):end]
                if !isempty(current_branches)
                    try
                        run(`git push origin --delete $(current_branches)`)
                    catch ex
                        @info "Encountered an error while trying to delete multiple branches" exception=(ex, catch_backtrace()) current_branches
                    end
                end
            end
        end
    end
    with_cloned_repo(AUTOMERGE_INTEGRATION_TEST_REPO) do git_repo_dir
        cd(git_repo_dir) do
            all_origin_branches = list_all_origin_branches(git_repo_dir)::Vector{String}
            for branch_name in all_origin_branches
                if occursin(timestamp_regex, branch_name)
                    commit = strip(read(`git rev-parse origin/$(branch_name)`, String))
                    age = get_age_of_commit(commit)
                    if age >= older_than
                        try
                            run(`git push origin --delete $(branch_name)`)
                        catch ex
                            @info "Encountered an error while trying to delete branch" exception=(ex, catch_backtrace()) branch_name
                        end
                    end
                end
            end
        end
    end
    return nothing
end

function now_localzone()
    return TimeZones.now(TimeZones.localzone())
end

function get_age_of_commit(commit)
    commit_date_string = strip(read(`git show -s --format=%cI $(commit)`, String))
    commit_date = TimeZones.ZonedDateTime(commit_date_string, "yyyy-mm-ddTHH:MM:SSzzzz")
    now = TimeZones.ZonedDateTime(TimeZones.now(), TimeZones.localzone())
    age = max(now - commit_date, Dates.Millisecond(0))
    return age
end

function list_all_origin_branches(git_repo_dir)
    result = Vector{String}(undef, 0)
    original_working_directory = pwd()
    cd(git_repo_dir)
    a = try
        read(`git branch -a`, String)
    catch
        ""
    end
    b = split(strip(a), '\n')
    b_length = length(b)
    c = Vector{String}(undef, b_length)
    for i = 1:b_length
        c[i] = strip(strip(strip(b[i]), '*'))
        c[i] = first(split(c[i], "->"))
        c[i] = strip(c[i])
    end
    my_regex = r"^remotes\/origin\/(.*)$"
    for i = 1:b_length
        if occursin(my_regex, c[i])
            m = match(my_regex, c[i])
            if m[1] != "HEAD"
                push!(result, m[1])
            end
        end
    end
    cd(original_working_directory)
    return result
end

function with_cloned_repo(f, repo_url)
    return mktempdir() do tmp_dir
        return cd(tmp_dir) do
            git_repo_dir = joinpath(tmp_dir, "REPO")
            run(`git clone $(repo_url) REPO`)
            return cd(git_repo_dir) do
                return f(git_repo_dir)
            end
        end
    end
end

function empty_git_repo(git_repo_dir::AbstractString)
    original_working_directory = pwd()
    cd(git_repo_dir)
    for x in readdir(git_repo_dir)
        if x != ".git"
            path = joinpath(git_repo_dir, x)
            rm(path; force = true, recursive = true)
        end
    end
    cd(original_working_directory)
    return nothing
end

function _generate_branch_name(name::AbstractString)
    sleep(5)
    _now = now_localzone()
    _now_utc_string = utc_to_string(_now)
    b = "integration/$(_now_utc_string)/$(rand(UInt32))/$(name)"
    sleep(5)
    return b
end

function generate_branch(name::AbstractString,
                         path_to_content::AbstractString,
                         parent_branch::AbstractString = "master";
                         repo_url)
    original_working_directory = pwd()
    b = _generate_branch_name(name)
    with_cloned_repo(repo_url) do git_repo_dir
        cd(git_repo_dir)
        run(`git checkout $(parent_branch)`)
        run(`git branch $(b)`)
        run(`git checkout $(b)`)
        empty_git_repo(git_repo_dir)
        for x in readdir(path_to_content)
            src = joinpath(path_to_content, x)
            dst = joinpath(git_repo_dir, x)
            rm(dst; force = true, recursive = true)
            cp(src, dst; force = true)
        end
        cd(git_repo_dir)
        CompatHelper.my_retry(() -> run(`git add -A`))
        CompatHelper.my_retry(() -> run(`git commit -m "Automatic commit - CompatHelper integration tests"`))
        CompatHelper.my_retry(() -> run(`git push origin $(b)`))
        cd(original_working_directory)
        rm(git_repo_dir; force = true, recursive = true)
    end
    return b
end

function generate_master_branch(path_to_content::AbstractString,
                                parent_branch::AbstractString = "master";
                                repo_url)
    name = "master"
    b = generate_branch(name, path_to_content, parent_branch; repo_url = repo_url)
    return b
end

function templates(parts...)
    this_filename = @__FILE__
    test_directory = dirname(this_filename)
    templates_directory = joinpath(test_directory, "templates")
    result = joinpath(templates_directory, parts...)
    return result
end

function username(auth::GitHub.Authorization)
    sleep(5)
    user_information = GitHub.gh_get_json(GitHub.DEFAULT_API,
                                          "/user";
                                          auth = auth)
    sleep(5)
    return user_information["login"]::String
end

function utc_to_string(zdt::TimeZones.ZonedDateTime)
    zdt_as_utc = TimeZones.astimezone(zdt, TimeZones.tz"UTC")
    year = TimeZones.Year(zdt_as_utc.utc_datetime).value
    month = TimeZones.Month(zdt_as_utc.utc_datetime).value
    day = TimeZones.Day(zdt_as_utc.utc_datetime).value
    hour = TimeZones.Hour(zdt_as_utc.utc_datetime).value
    minute = TimeZones.Minute(zdt_as_utc.utc_datetime).value
    second = TimeZones.Second(zdt_as_utc.utc_datetime).value
    millisecond = TimeZones.Millisecond(zdt_as_utc.utc_datetime).value
    result = Printf.@sprintf "%04d-%02d-%02d-%02d-%02d-%02d-%03d" year month day hour minute second millisecond
    return result
end

function with_master_branch(f::Function,
                            path_to_content::AbstractString,
                            parent_branch::AbstractString;
                            repo_url)
    b = generate_master_branch(path_to_content,
                               parent_branch;
                               repo_url = repo_url)
    result = f(b)
    return result
end
