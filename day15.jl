filename() = "day15.txt"

"""
Read data and return a pair of data structures:
1. A dictionary of tuples where K=spoken number, V=(lastpos,recentpos)
2. An array of spoken numbers
"""
function read_data()
    seq = parse.(Int, split(readline(filename()), ","))
    return Dict(v => (0, k) for (k,v) in enumerate(seq)), seq
end

"""
Solve the puzzle with a simple loop. Since we always spoken the last
spoken number, the Dict is guaranteed to have a value.

If the first value of the tuple is 0, then it is a starting value and say 0;
otherwise, say the difference of values in that tuple. Then, update the
Dict for the spoken number with a new tuple.
"""
function solve(year)
    dct, seq = read_data()
    start = length(seq) + 1
    spoken = seq[end]
    for i in start:year
        tup = dct[spoken]
        val = tup[1] == 0 ? 0 : tup[2] - tup[1]
        if haskey(dct, val)
            dct[val] = (dct[val][2], i)
        else
            dct[val] = (0, i)
        end
        spoken = val
    end
    return spoken
end

part1() = solve(2020)
part2() = solve(30000000)

#=
julia> @benchmark part2()
BenchmarkTools.Trial: 
  memory estimate:  395.84 MiB
  allocs estimate:  84
  --------------
  minimum time:     2.576 s (0.32% GC)
  median time:      2.583 s (1.69% GC)
  mean time:        2.583 s (1.69% GC)
  maximum time:     2.591 s (3.05% GC)
  --------------
  samples:          2
  evals/sample:     1
=#

using Plots

function animation(year)
    anim = Animation()
    dct, seq = read_data()
    start = length(seq) + 1
    spoken = seq[end]
    plot(seq, background_color = :black, legend = :none,
        xlabel = "Year", ylabel = "Number Spoken",
        title = "Advent of Code (Day 15)",
        size = (500,300),
        xlims = (1, 2100),
        ylims = (1, 1600))
    for i in start:year
        tup = dct[spoken]
        val = tup[1] == 0 ? 0 : tup[2] - tup[1]
        if haskey(dct, val)
            dct[val] = (dct[val][2], i)
        else
            dct[val] = (0, i)
        end
        spoken = val
        push!(seq, spoken)
        if i % 20 == 0
            plot!(seq[1:i])
            frame(anim)
        end
    end
    return gif(anim, "day15_anim.gif"; fps = 25)
end