function parse_line(s)
    m = match(r"(\d+)-(\d+) (.): (.*)$", s).captures
    return (min = parse(Int, m[1]), max = parse(Int, m[2]), letter = m[3][begin], pwd = m[4])
end

records = parse_line.(readlines("day02.txt"))

using StatsBase

# Part1
# Find number of valid passwords with at least and at most of a letter
count(r -> r.min <= get(countmap(r.pwd), r.letter, -1) <= r.max, records)

# Part2
# Find number of valid passwords with the letter at either min/max but not both
count(r -> xor(r.pwd[r.min] == r.letter, r.pwd[r.max] == r.letter) , records)
