filename() = "day17.txt"

function read_data(dims)
    data = readlines(filename())
    keytype = Tuple{fill(Int, dims)...}
    padding = fill(0, dims - 2)
    world = Dict{keytype,Bool}()
    for r in 1:length(data)
        for c in 1:length(data[r])
            world[(r, c, padding...)] = data[r][c] == '#'
        end
    end
    return world
end

"""
Count how many neighbors are active.
"""
function count_active_neigbors(A, p, dims = 3)
    cnt = 0
    origin = tuple(fill(0, dims)...)
    rel = Iterators.product(fill([1,0,-1], dims)...)
    for r in rel
        if r != origin  # exclude myself
            q = p .+ r  # neighbor coordinates
            if get(A, q, false)
                cnt += 1
            end
        end
    end
    return cnt
end

"""
Find the range for the outer layer at dimension `dim`.
"""
function span(world, dim)
    ex = extrema(k[dim] for k in keys(world))
    low, high = ex[1] - 1, ex[2] + 1
    return range(low, high; step = 1)
end

is_active(world, p) = haskey(world, p) && world[p]

function solve(dims, iterations)
    world = read_data(dims)
    for i in 1:iterations
        # Becuase all cubes changes state simultaneously, we must not
        # mutate the current world. Make a copy of the world and mutate
        # the new one only.
        new_world = copy(world)
        
        # Find all ranges at all dimensions
        spans = span.(Ref(world), 1:dims)

        # Iterate all possible cubes within the world. This is actually
        # very inefficient because all coordinates within the whole
        # world are considered.
        for cube in Iterators.product(spans...)
            active = is_active(world, cube)
            active_neighbors = count_active_neigbors(world, cube, dims)
            if active && active_neighbors ∉ [2,3]
                new_world[cube] = false
            elseif !active && active_neighbors == 3
                new_world[cube] = true
            end
        end

        # Switch over to the new world after each iteration
        world = new_world
    end
    return count(values(world))
end

part1() = solve(3, 6)
part2() = solve(4, 6)
