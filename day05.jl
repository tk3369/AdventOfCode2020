# part 1

# This is really just the binary representation of an integer in disguise!

row(s) = parse(Int, replace(replace(s[1:7], "F"=>"0"), "B"=>"1"); base = 2)
col(s) = parse(Int, replace(replace(s[8:10], "L"=>"0"), "R"=>"1"); base = 2)
id(s) = row(s) * 8 + col(s)

# quick test
row("BFFFBBFRRR")
col("BFFFBBFRRR")
id("BFFFBBFRRR")

id("FFFBBBFRRR") == 119
id("BBFFBBFRLL") == 820

# read data
lines = readlines("day05.txt")
boarding_passes = id.(lines)

# part 1
maximum(boarding_passes)  # 980

# part 2
sorted = sort(boarding_passes)
argmax([sorted[i] - sorted[i-1] > 1 for i in 2:length(sorted)])  # 567
sorted[566:569]

#=
julia> sorted[566:569]
4-element Vector{Int64}:
 605
 606
 608
 609
=#

using BenchmarkTools

# From Aaron on Discord
seatnumber(line) = mapfoldl(c->c in "BR", (x, y)->2x+y, line, init=0)
seatnumber("BFFFBBFRRR")

# what if we benchmark that against parsing?
id2(s) = parse(Int, replace(replace(s, r"[FL]"=>"0"), r"[BR]"=>"1"); base = 2)

lines = readlines("day05.txt")

@btime seatnumber.($lines)  # 230 μs
@btime id2.($lines)  # 1.18 ms

aaron_part1a(lines) = mapfoldl.(∈("BR"), (x,y) -> 2x + y, lines)
@btime aaron_part1a($lines);

aaron_part1b(lines) = mapfoldl.(∈(('B', 'R')), (x,y) -> 2x + y, lines)
@btime aaron_part1b($lines);

using Base.Threads

function loop(lines)
    max_id = 0
    @inbounds for line in lines
        val = 0
        for c in line
            val <<= 1
            val += c in ('B', 'R') ? 1 : 0
        end
        if val > max_id
            max_id = val
        end
    end
    return max_id
end
loop(lines)
@btime loop($lines);
@btime loop($lines);
@btime loop($lines);
@btime loop($lines);

# Conclusion: mapfoldr rocks!

# code golf style from braden@Discord
S=sort(mapfoldl.(∈("BR"),(x,y)->2x+y,readlines("day05.txt")));S[end],S[argmax(diff(S))]+1
