module CompatHelper

using Base64: Base64
using Dates: Dates
using GitForge: GitForge, Forge, GitHub, GitLab
using MultilineStrings
using Mocking: Mocking, @mock
using Pkg: Pkg
using TimeZones: TimeZones
using TOML: TOML
using UUIDs: UUIDs, UUID

export DropEntry, KeepEntry, NewEntry
export CIService, GitHubActions, GitLabCI

@static if Base.VERSION >= v"1.7-"
    const VersionSpec = Pkg.Versions.VersionSpec
    const semver_spec = Pkg.Versions.semver_spec
else
    const VersionSpec = Pkg.Types.VersionSpec
    const semver_spec = Pkg.Types.semver_spec
end

const PRIVATE_SSH_ENVVAR = "COMPATHELPER_PRIV"

include(joinpath("utilities", "types.jl"))
include(joinpath("utilities", "utilities.jl"))
include(joinpath("utilities", "ci.jl"))
include(joinpath("utilities", "git.jl"))
include(joinpath("utilities", "ssh.jl"))
include(joinpath("utilities", "timestamps.jl"))
include(joinpath("utilities", "new_versions.jl"))

include("main.jl")
include("exceptions.jl")
include("dependencies.jl")
include("pull_requests.jl")

end # module
