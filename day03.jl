filename() = "day03_sample.txt"

# Read file. Repeat horizontally certain number of times.
lines(repeat) = [r^repeat for r in readlines(filename())]

# Part1
# Walk down the grid according to "right 3, 1 down" rule.
# Count how many trees (`#` sign) that I encounter.
# 32 times because 323 * 3 / 31 = 31.26
part1() = count([val[(row-1)*3+1] == '#' for (row,val) in enumerate(lines(32))])

# Part2
# Customized rule with `right` and `down` values.
function count_trees(lines, right, down)
    col = 1
    cnt = 0
    for row in 1:down:length(lines)
        row > 1 || continue
        col += right
        if lines[row][col] == '#'
            cnt += 1
        end
    end
    return cnt
end

function part2()
    grid = lines(73)
    counts = [count_trees(grid, x[1], x[2]) for x in ((1,1),(3,1),(5,1),(7,1),(1,2))]
    return prod(counts)
end
