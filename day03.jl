# Read file. Repeat 32 times because 323 * 3 / 31 = 31.26
lines = [r^32 for r in readlines("day03.txt")]

# part1
count([val[(row-1)*3+1] == '#' for (row,val) in enumerate(lines)])

# part2
function count_trees(lines, right, down)
    col = 1
    cnt = 0
    for row in 1:down:length(lines)
        row > 1 || continue
        col += right
        if lines[row][col] == '#'
            @info "Found at ($row, $col)"
            cnt += 1
        end
    end
    return cnt
end
count_trees(sample, 1, 2)

# 323 * 7 / 31 = 73
lines = [r^73 for r in readlines("day03.txt")]
counts = [count_trees(lines, x[1], x[2]) 
    for x in ((1,1),(3,1),(5,1),(7,1),(1,2))]
prod(counts)

# sample
sample = [r^50 for r in split("""..##.......
#...#...#..
.#....#..#.
..#.#...#.#
.#...##..#.
..#.##.....
.#.#.#....#
.#........#
#.##...#...
#...##....#
.#..#...#.#""", "\n")]
counts = [count_trees(sample, x[1], x[2]) 
    for x in ((1,1),(3,1),(5,1),(7,1),(1,2))]

count_trees(sample, 1, 2)