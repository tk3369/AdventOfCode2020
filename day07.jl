filename() = "day07.txt"
read_data() = split(String(read(filename())), "\n")

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

function part1()
    dct = build_bags_dict(read_data())
    part1(dct, "shiny gold")
end

# part 2

function weight(dct, color)
    helper(color) = 1 + mapreduce(c -> c[2] * helper(c[1]), +, dct[color].children; init = 0)
    return helper(color) - 1  # exclude myself
end

function part2()
    dct = build_bags_dict(read_data())
    return weight(dct, "shiny gold")
end


#------------------------------------------
# LightGraphs 

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

# e.g. part1_graph("shiny gold")
function part1_graph(target)
    graph, rules = build_digraph(readlines(filename()))
    target_index = bag_index(rules, target)
    return count([has_path(graph, i, target_index) for i in 1:nv(graph) if i !== target_index])
end

# --------------------------------------------------
# Visualization

using GraphPlot
using Cairo, Compose, Colors

function plot_pdf()
    lines = readlines(filename())
    graph, rules = build_digraph(lines)

    nodelabel = [bag_color(rules, i) for i in 1:length(rules)]
    nodecolor = [bag_color(rules, i) == "shiny gold" ? colorant"firebrick1" : colorant"honeydew" 
        for i in 1:length(rules)]

    draw(PDF("day07.pdf", 100cm, 100cm), 
        gplot(graph, nodelabel=nodelabel, nodefillc=nodecolor, arrowlengthfrac=0.01))

    return gplot(graph, nodelabel=nodelabel)
end
