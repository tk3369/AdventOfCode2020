# read data
groups = split(String(read("day06.txt")), "\n\n")

# part 1
count_unique(s) = length(unique(collect(replace(s, "\n"=>""))))
count_unique.(groups) |> sum

# part 2
function count_everyone(s) 
    set = Set(collect('a':'z'))
    for p in people
        new_set = collect(p)
        intersect!(set, new_set)
    end
    return length(set)
end
count_everyone.(groups) |> sum

# part 2 (refactored)
count_everyone(s) = length(intersect(collect.(split(s, "\n"))...))
count_everyone.(groups) |> sum
