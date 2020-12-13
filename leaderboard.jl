"""
A quick and dirty moduel for retrieving privarte leaderboard data from AoC.
"""
module Leaderboard

using Dates
using Downloads
using JSON
using DataFrames

function __init__()
    get_data()
end

function get_data()
    url = "https://adventofcode.com/2020/leaderboard/private/view/213962.json"
    file = Downloads.download(
        url, 
        headers = Dict("Cookie" => "session=" * ENV["AOC_SESSION_COOKIE"])
    )
    global json = JSON.parse(String(read(file)))
end

player_name(id, name) = name === nothing ? string("(anon user ", id, ")") : lowercase(name)

function find_player_by_id(id)
    return json["members"]["$id"]
end

function find_player(name::String)
    return last(pop!(filter(json["members"]) do p
        id, details = p
        occursin(lowercase(name), player_name(id, details["name"]))
    end))
end

function convert_time(seconds_string)
    seconds = parse(Int, seconds_string)
    dt = unix2datetime(seconds)
    return dt - Hour(5)  # adjust from UTC to EST(-0500)
end

function get_star_ts(stats, day, part)
    cdl = stats["completion_day_level"]
    haskey(cdl, "$day") || return missing
    haskey(cdl["$day"], "$part") || return missing
    haskey(cdl["$day"]["$part"], "get_star_ts") || return missing
    return convert_time(cdl["$day"]["$part"]["get_star_ts"])
end

function summary(id)
    stats = find_player_by_id(id)
    df = DataFrame(day = 1:25, date = Date(2020,12,1):Day(1):Date(2020,12,25), name = player_name(id, stats["name"]))
    df.part1 = get_star_ts.(Ref(stats), df.day, 1)
    df.part2 = get_star_ts.(Ref(stats), df.day, 2)
    transform!(df, [:part1, :date] => ByRow((x,y) -> x !== missing ? Second(x - DateTime(y)) : missing) => :elapsed1)
    transform!(df, [:part1, :part2] => ByRow((x,y) -> x!==missing && y!==missing ? Second(y-x) : missing) => :elapsed2)
    transform!(df, [:elapsed1, :elapsed2] => ByRow((x,y) -> x!==missing && y!==missing ? x+y : missing) => :total_elapsed)
    return filter(r -> r.part1 !== missing || r.part2 !== missing, df)
end

function all_player_stats()
    player_names = [haskey(d, "name") ? d["name"] : string("(anonymous user ", d["id"], ")")
        for d in values(json["members"])]
    return reduce(vcat, (summary(id) for id in keys(json["members"])))
end

function check_day(day)
    data = filter(:day => ==(day), Leaderboard.all_player_stats())
    return sort(data, [:total_elapsed, :elapsed1])
end

end # module

# Sample usage
using .Leaderboard
Leaderboard.check_day(13)
