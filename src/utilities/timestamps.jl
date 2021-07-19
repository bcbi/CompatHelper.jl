@inline now_localzone() = TimeZones.now(TimeZones.localzone())

function utc_to_string(zdt::TimeZones.ZonedDateTime)
    zdt_as_utc = TimeZones.astimezone(zdt, TimeZones.tz"UTC")
    return Dates.format(zdt_as_utc, "yyyy-mm-dd-HH-MM-SS-sss")
end
