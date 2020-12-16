filename() = "day16.txt"

function read_data()
    data = String(read(filename()))
    blocks = split(data, "\n\n")
    
    function parse_rule(line)
        name, x = split(line, ": ")
        r1, r2 = split(x, " or ")
        r1 = range(parse.(Int, split(r1, "-"))...; step = 1)
        r2 = range(parse.(Int, split(r2, "-"))...; step = 1)
        return (name = name, ranges = [r1, r2])
    end

    function parse_ticket(line)
        return parse.(Int, split(line, ","))
    end

    return (
        rules = parse_rule.(split(blocks[1], "\n")),
        my_ticket = parse_ticket(split(blocks[2], "\n")[2]),
        nearby_tickets = parse_ticket.(split(blocks[3], "\n")[2:end])
    )
end

# ----------------------------------------------------------------------
# Part 1
# ----------------------------------------------------------------------

"""
Returns `true` if the value does not appear in any of the rules
"""
function error_val(rules, value)
    return !any(in.(value, rules))
end

"""
Return the sum of bad field values from the `ticket` 
(which is an array of field values)
"""
function error_sum(rules, ticket)
    bad_values = filter(v -> error_val(rules, v), ticket)
    return sum(bad_values)
end

function part1(input)
    rule_ranges = collect(Iterators.flatten([r.ranges for r in input.rules]))
    return sum(error_sum(rule_ranges, t) for t in input.nearby_tickets)
end

# ----------------------------------------------------------------------
# Part 2
# ----------------------------------------------------------------------

"""
Return an array of rules that can be applied perfectly to all values.
but ignore the ones in the `excludes` dict.
"""
function candidate_fields(input, values, excludes)
    return [r for r in input.rules 
        if all(v ∈ r.ranges[1] || v ∈ r.ranges[2] for v in values) &&
            !haskey(excludes, r)]
end

"Gather values for a specific field from the provided tickets."
field_values(tickets, pos) = [t[pos] for t in tickets]

"Return number of fields in the input."
field_count(input) = length(input.my_ticket)

"Return all rules from the input as a flat array."
all_rules(input) = collect(Iterators.flatten([r.ranges for r in input.rules]))

"""
Return good nearby tickets, which is defined as not having any errors in
any of the fields.
"""
function good_nearby_tickets(input)
    rr = all_rules(input)
    [t for t in input.nearby_tickets if !any(error_val(rr, v) for v in t)]
end

"""
Figure out how each field is mapped to which rule using dynamic programming.

The algorithm uses a Dict to keep track of fields that can be mapped.
When the number of candidate rules for that field is determined to be 1, 
then we can map that field right away. Otherwise, we put that field back
into a queue and revisit that later.
"""
function part2_search(input)
    tickets = good_nearby_tickets(input)
    found = Dict{Any,Int}()  # rule -> pos mapping
    len = field_count(input)
    queue = collect(1:len)
    cnt = 0
    while length(found) < len
        pos = popfirst!(queue)
        cf = candidate_fields(input, field_values(tickets, pos), found)
        if length(cf) == 1
            # yay! we found a mapping!
            found[cf[1]] = pos
        elseif length(cf) > 1 
            # Push it back to queue and try again later
            push!(queue, pos)
        else
            error("not possible $pos")
        end
        cnt += 1
        cnt > 10000 && break  # just a circuit breaker
    end
    @show length(found) len   # integrity check
    return found
end

"""
Find mapping of fields and rules. Then, look up my ticket and multiply
the values for fields that start with the word `departure`.
"""
function part2()
    input = read_data()
    dct = part2_search(input)
    positions = [v for (k,v) in dct if startswith(k.name, "departure")]
    return prod(input.my_ticket[positions])
end