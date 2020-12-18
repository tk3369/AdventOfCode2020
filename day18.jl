filename() = "day18.txt"

using MacroTools

function read_data()
    return readlines(filename())
end

#=
Replace + operators with / to equalize precedence with *.
Then, leverage the Julia parser. Finally, restore the +
operators using MacroTools.postwallk.
=#
function part1()
    function evaluate(line)
        revised = replace(line, "+" => "/")
        expr = Meta.parse(revised)
        expr = MacroTools.postwalk(x -> x == :(/) ? :(+) : x, expr)
        return eval(expr)
    end
    return sum(evaluate.(read_data()))
end

#=
Same trick as above to implement the reversed precedence rules.
=#
function part2()
    function evaluate(line)
        revised = replace(replace(line, "*" => "-"), "+" => "/")
        expr = Meta.parse(revised)
        expr = MacroTools.postwalk(x -> ifelse(x == :(/), :(+), ifelse(x == :(-), :(*), x)), expr)
        return eval(expr)
    end
    return sum(evaluate.(read_data()))
end
