struct UnableToParseSSHKey <: Exception
    message::AbstractString
end
Base.show(io::IO, e::UnableToParseSSHKey) = println(io, e.message)

struct UnableToDetectCIService <: Exception
    message::AbstractString
end
Base.show(io::IO, e::UnableToDetectCIService) = println(io, e.message)
