function parse_line(s)
    m = match(r"(\d+)-(\d+) (.): (.*)$", s).captures
    return (min = parse(Int, m[1]), max = parse(Int, m[2]), letter = m[3][begin], pwd = m[4])
end

records = parse_line.(readlines("day02.txt"))

using StatsBase

# part1
count(r -> r.min <= get(countmap(r.pwd), r.letter, -1) <= r.max, records)

# part2
count(r -> xor(r.pwd[r.min] == r.letter, r.pwd[r.max] == r.letter) , records)
