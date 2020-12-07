sample = split("""light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags.""", "\n")

# part 1

struct BagRule
    color::String
    children::Vector{Pair{String,Int}}
end

function parse_rule(s)
    m = match(r"^(.*) bags contain (.*)\.", s)
    bag = m.captures[1]
    return if startswith(m.captures[2], "no other")
        [(bag = bag, qty = 0, inner = "")]
    else
        inner = split(m.captures[2], r", *")
        [let m = match(r"^(\d+) (.*)$", replace(bag_with_number, r" bags*" => "")) 
            (bag = bag, qty = parse(Int, m.captures[1]), inner = m.captures[2])
        end for bag_with_number in inner] 
    end
end

function build_bags_dict(lines)
    dct = Dict()
    for line in lines
        rules = parse_rule(line)
        color = rules[1].bag
        rule = BagRule(color, Pair{String,Int}[])
        for r in rules
            r.qty > 0 && push!(rule.children, r.inner => r.qty)
        end
        dct[color] = rule
    end
    return dct
end

function part1(dct, target)
    function dfs(color)
        !haskey(dct, color) || isempty(dct[color].children) && return 0
        color == target && return 1
        return sum(dfs(c[1]) for c in dct[color].children)
    end
    return count(dfs(k) > 0 for k in keys(dct) if k != target)
end

sample_dict = build_bags_dict(sample)
part1(sample_dict, "shiny gold")

bags_dict = build_bags_dict(readlines("day07.txt"))
part1(bags_dict, "shiny gold")

# part 2

function weight(dct, color)
    helper(color) = 1 + mapreduce(c -> c[2] * helper(c[1]), +, dct[color].children; init = 0)
    return helper(color) - 1  # exclude myself
end

weight(sample_dict, "shiny gold")
weight(bags_dict, "shiny gold")

#------------------------------------------
# LightGraphs visualization

using LightGraphs, SimpleWeightedGraphs

bag_index(rules, color::AbstractString) = findfirst(r -> r[1].bag == color, rules)
bag_color(rules, idx::Int) = rules[idx][1].bag

function build_digraph(lines)
    graph = SimpleWeightedDiGraph(length(lines))
    rules = parse_rule.(lines)  # array of array of named tuples
    for r in rules
        outer_bag_index = bag_index(rules, r[1].bag)
        for directed in r
            if directed.qty > 0
                inner_bag_index = bag_index(rules, directed.inner)
                add_edge!(graph, outer_bag_index, inner_bag_index, directed.qty)
            end
        end
    end
    return (; graph, rules)
end
sample_graph, sample_rules = build_digraph(sample)

using GraphPlot
nodelabel = [bag_color(sample_rules, i) for i in 1:length(sample_rules)]
gplot(sample_graph, nodelabel=nodelabel)

# Let's try the real thing
lines = readlines("day07.txt")
graph, rules = build_digraph(lines)

using Cairo, Compose, Colors
nodelabel = [bag_color(rules, i) for i in 1:length(rules)]
nodecolor = [bag_color(rules, i) == "shiny gold" ? colorant"firebrick1" : colorant"honeydew" for i in 1:length(rules)]
gplot(graph, nodelabel=nodelabel)

draw(PDF("day07.pdf", 100cm, 100cm), 
    gplot(graph, nodelabel=nodelabel, nodefillc=nodecolor, arrowlengthfrac=0.01))


# From Jeffrey Lin on Slack
#=
struct Bag
    color::String
    quant::Int
end

function parse_rules(filename)
    rules = Dict{String, Vector{Bag}}()
    for line in eachline(filename)
        color, rest = split(line, " bags contain ")
        rawrules = filter(!isnothing, match.(r"([0-9]) ([a-z]+ [a-z]+) bag", split(rest, ",")))
        rules[color] = rawrules .|> x -> x.captures |> x -> Bag.(x[2], parse(Int, x[1]))
    end
    rules
end


function resolve(rules, color)
    color == "shiny gold" || any(cc -> resolve(rules, cc.color), rules[color])
end

function solve_a(filename = save_input(2020, 7))
    rules = parse_rules(filename)

    count(keys(rules)) do color
        color != "shiny gold" && resolve(rules, color)
    end
end

function resolve2(rules, color)
    if length(rules[color]) > 0
        1 + sum(cc -> cc.quant * resolve2(rules, cc.color), rules[color])
    else
        1
    end
end

function solve_b(filename = save_input(2020, 7))
    rules = parse_rules(filename)
    resolve2(rules, "shiny gold") - 1
end
=#
