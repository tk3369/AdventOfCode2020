filename() = "day22.txt"

function read_data()
    blocks = split(String(read(filename())), "\n\n")
    parse_block(b) = parse.(Int, split(b, "\n")[2:end])
    return parse_block.(blocks)
end

function play(p1, p2)
    while length(p1) > 0 && length(p2) > 0
        c1, c2 = popfirst!(p1), popfirst!(p2)
        if c1 > c2
            append!(p1, [c1, c2])
        else
            append!(p2, [c2, c1])
        end 
    end
    return length(p1) > 0 ? p1 : p2
end

function part1()
    p1, p2 = read_data()
    hands = play(p1, p2)
    multipliers = range(length(hands), 1, step = -1)
    return sum(hands .* multipliers)
end

function play2(p1, p2)
    mem = Set()
    while length(p1) > 0 && length(p2) > 0

        # check for instant win, else remember this round
        hash((p1,p2)) ∈ mem && return (1, p1)
        push!(mem, hash((p1,p2)))

        # draw cards
        c1, c2 = popfirst!(p1), popfirst!(p2)

        # play sub game?
        if length(p1) >= c1 && length(p2) >= c2
            winner, _ = play2(copy(p1)[1:c1], copy(p2)[1:c2])
        else
            winner = c1 > c2 ? 1 : 2
        end

        if winner == 1
            append!(p1, [c1, c2])
        else
            append!(p2, [c2, c1])
        end 
    end
    return length(p1) > 0 ? (1, p1) : (2, p2)
end

function part2()
    p1, p2 = read_data()
    winner, hands = play2(p1, p2)
    multipliers = range(length(hands), 1, step = -1)
    return sum(hands .* multipliers)
end
