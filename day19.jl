filename() = "day19.txt"

# wraps patterns in parentheses
datum(x::String) = "($x)"
datum(x::Vector{String}) = datum(join(datum.(x)))
datum(x::Vector{Vector{String}}) = datum(join(datum.(x), "|"))

"""
The rules are parsed into a Dict that looks like this:

julia> read_data("day19_sample.txt")[1]
Dict{String,String} with 6 entries:
  "(2)" => "(((4)(4))|((5)(5)))"
  "(5)" => "(b)"
  "(1)" => "(((2)(3))|((3)(2)))"
  "(3)" => "(((4)(5))|((5)(4)))"
  "(4)" => "(a)"
  "(0)" => "((4)(1)(5))"
"""
function read_data(file)
    blocks = split(String(read(file)), "\n\n")

    rules = Dict(let v = string.(split(r, r":* "))
                    k = v[1]
                    if startswith(v[2], "\"")  # final term
                        datum(k) => datum(v[2][2:end-1])
                    elseif "|" ∈ v[2:end]      # multiple choices
                        d = findfirst(==("|"), v)
                        datum(k) => datum([v[2:d-1], v[d+1:end]])
                    else                       # single choice
                        datum(k) => datum(v[2:end])
                    end
                 end for r in split(blocks[1], "\n"))

    messages = split(blocks[2], "\n")
    
    return rules, messages
end

"""
Given the rules, resolve the variables into terminal strings "a" and "b"
and then return a `Regex` object.
"""
function make_regex(rules)
    str = rules["(0)"]
    while match(r"\([0-9]+\)", str) !== nothing
        for (k,v) in rules
            str = replace(str, k => v)
        end
    end
    for i in 1:10  # trim parentheses to reduce size of regex
        str = replace(str, r"\(([ab]*)\)" => s"\1")
    end
    str = "^" * str * "\$"
    # @show str
    return Regex(str)
end

function part1()
    rules, messages = read_data(filename())
    re = make_regex(rules)
    return count(m -> !isnothing(match(re, m)), messages)
end

function part2()
    rules, messages = read_data(filename())
    rules["(8)"] = "((42)+)"
    return sum(1:8) do i
        rules["(11)"] = "((42){$i}(31){$i})"
        re = make_regex(rules)
        count(m -> !isnothing(match(re, m)), messages)
    end
end

# For some reasons, regex recursion did not work: "((42)(?R)?(31))"
function part2b()
    rules, messages = read_data()
    rules["(8)"] = "((42)+)"
    rules["(11)"] = "((42)(?R)?(31))"
    re = make_regex(rules)
    return count(m -> !isnothing(match(re, m)), messages)
end
