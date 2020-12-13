filename() = "day06.txt"

# read data
read_data() = split(String(read(filename())), "\n\n")

# Part 1
function part1()
    # how many unique poeple are in this set
    count_unique(s) = length(unique(collect(replace(s, "\n"=>""))))
    return count_unique.(read_data()) |> sum
end

# Part 2
# Count everyone who answered 'yes', so we just need to take the intersection
# of all people.
function count_everyone(line) 
    people = split(line, "\n")
    set = Set(collect('a':'z'))
    for p in people
        new_set = collect(p)
        intersect!(set, new_set)
    end
    return length(set)
end

part2() = count_everyone.(read_data()) |> sum

# part 2 (refactored using splatting)
count_everyone_splat(s) = length(intersect(collect.(split(s, "\n"))...))
part2b() = count_everyone_splat.(read_data()) |> sum
