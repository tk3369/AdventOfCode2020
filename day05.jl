data() = readlines("day05.txt")

# This is really just the binary representation of an integer in disguise!
row(s) = parse(Int, replace(replace(s[1:7], "F"=>"0"), "B"=>"1"); base = 2)
col(s) = parse(Int, replace(replace(s[8:10], "L"=>"0"), "R"=>"1"); base = 2)
id(s) = row(s) * 8 + col(s)

# quick test
# row("BFFFBBFRRR")
# col("BFFFBBFRRR")
# id("BFFFBBFRRR")

# id("FFFBBBFRRR") == 119
# id("BBFFBBFRLL") == 820

# read data
boarding_passes = id.(data())

# part 1
part1() = maximum(boarding_passes)  # 980

# part 2
function part2()
    sorted = sort(boarding_passes)
    idx = argmax([sorted[i] - sorted[i-1] > 1 for i in 2:length(sorted)])  # 567
    return sorted[idx] + 1
end

# using BenchmarkTools

# From Aaron on Discord. The mapfoldl function is awesome in terms of performance!
seatnumber(line) = mapfoldl(c->c in "BR", (x, y)->2x+y, line, init=0)
seatnumber("BFFFBBFRRR")
