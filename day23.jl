using CircularList

function play!(L, n)
    
    highest = maximum(L)
    lowest = minimum(L)
    dct = build_dict(L)

    for i in 1:n
        curr = current(L)

        # Pick 3 numbers
        forward!(L)
        v1 = current(L).data; delete!(L); forward!(L)
        v2 = current(L).data; delete!(L); forward!(L)
        v3 = current(L).data; delete!(L); forward!(L)

        # Choose a destination value as 1 less than current label
        dst = curr.data - 1

        # Make sure destination isn't one of those that were just picked up
        # Also, wraps around to the highest value if needed
        for j in 1:3
            if dst < lowest
                dst = highest
            end
            if dst in [v1, v2, v3]
                dst -= 1
            end
        end

        # Jump to the destination node
        jump!(L, dct[dst])

        # Re-insert the picked up cups
        insert_cup!(L, v1, dct)
        insert_cup!(L, v2, dct)
        insert_cup!(L, v3, dct)

        # Jump back to the current cup
        jump!(L, dct[curr.data])

        # Move to the next cup and repeat
        forward!(L)
    end

    # Jump to cup #1 and return the current list
    jump!(L, dct[1])
    return L
end

# Build a Dict for fast node lookup
function build_dict(L::CircularList.List{T}) where T
    dct = Dict{T, CircularList.Node{T}}()
    for i in 1:length(L)
        node = current(L)
        dct[node.data] = node
        forward!(L)
    end
    return dct
end

# Insert a cup to the list and update the dctionary lookup
function insert_cup!(L, value, dct)
    insert!(L, value)
    dct[value] = current(L)
    return nothing
end

# Calculate part1 result
function part1_result(L)
    v = collect(L)
    popfirst!(v)
    return join(v)
end

input() = [5,2,3,7,6,4,8,1,9]

part1() = play!(circularlist(input()), 100) |> part1_result

function part2()
    n = 10_000_000

    L = circularlist(vcat(input(), collect(10:1_000_000)))
    @info "Constructed list of $(length(L)) elements"
    
    play!(L, n)
    @info "Played $n times"

    forward!(L); v1 = current(L).data
    forward!(L); v2 = current(L).data
    @info "Completed game" v1 v2
    return v1 * v2
end

#=
julia> @time part2()
[ Info: Constructed list of 1000000 elements
[ Info: Played 10000000 times
┌ Info: Completed game
│   v1 = 760147
└   v2 = 673265
 35.447427 seconds (202.37 M allocations: 8.511 GiB, 40.76% gc time)
=#