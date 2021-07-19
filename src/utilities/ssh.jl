function is_raw_ssh_private_key(content::AbstractString)
    x1 = occursin("-", content)
    x2 = occursin(" ", content)
    x3 = occursin("BEGIN ", content)
    x4 = occursin("END ", content)
    x5 = occursin(" PRIVATE KEY", content)

    return x1 && x2 && x3 && x4 && x5
end

function decode_ssh_private_key(content::AbstractString)
    if is_raw_ssh_private_key(content)
        @info("This is a raw SSH private key.")
        return content
    end

    @info(
        "This doesn't look like a raw SSH private key. I will assume that it is a Base64-encoded SSH private key. I will now try to Base64-decode it."
    )
    decoded_content = String(Base64.base64decode(content))

    if !is_raw_ssh_private_key(decoded_content)
        msg = string(
            "Private key is not in the correct format. ",
            "It must be a private key in PEM format. ",
            "You should use the OpenSSH `ssh-keygen` command to generate the private key. ",
            "You should pass the `-m PEM` option to ensure that the private key is in PEM format.",
        )
        throw(UnableToParseSSHKey(msg))
    end

    @info(
        "This was a Base64-encoded SSH private key. I Base64-decoded it, and now I have the raw SSH private key."
    )
    return decoded_content
end
