abstract type EntryType end
struct KeepEntry <: EntryType end
struct DropEntry <: EntryType end
struct NewEntry <: EntryType end

struct DefaultBranch end

struct Package
    name::String
    uuid::UUIDs.UUID
end

mutable struct DepInfo
    package::Package
    latest_version::Union{VersionNumber,Nothing}
    version_spec::Union{VersionSpec,Nothing}
    version_verbatim::Union{String,Nothing}

    function DepInfo(
        package::Package;
        latest_version::Union{VersionNumber,Nothing}=nothing,
        version_spec::Union{VersionSpec,Nothing}=nothing,
        version_verbatim::Union{String,Nothing}=nothing,
    )
        return new(package, latest_version, version_spec, version_verbatim)
    end
end

function Base.in(p::Package, s::Set{DepInfo})
    for i in s
        if i.package == p
            return true
        end
    end

    return false
end
