using StatsBase

filename() = "day10.txt"
read_data() = parse.(Int, readlines(filename()))

function part1(data)
    sort!(data)
    v = vcat(0, data, data[end]+3)
    return prod(values(countmap(diff(v))))
end

function part2(data)
    sort!(data)
    v = vcat(0, data, data[end]+3)
    len = length(v)
    dct = Dict{Int,Int}()
    function helper(v, i)
        haskey(dct, i) && return dct[i]
        i == len && return 1
        n1 =               v[i+1] - v[i] <= 3 ? helper(v, i+1) : 0
        n2 = i+2 <= len && v[i+2] - v[i] <= 3 ? helper(v, i+2) : 0
        n3 = i+3 <= len && v[i+3] - v[i] <= 3 ? helper(v, i+3) : 0
        val = n1 + n2 + n3
        dct[i] = val
        return val
    end
    helper(v, 1)
end

main() = let v = read_data()
    @show part1(v)
    @show part2(v)
    nothing
end

# Performance

#=
julia> @btime part1($d)
  2.171 μs (28 allocations: 4.09 KiB)
1914

julia> @btime part2($d)
  13.625 μs (158 allocations: 10.22 KiB)
9256148959232
=#

#-- community solutions--

# James Doss-Gollin
function james()
    parse_file(fname) = parse.(Int, readlines(fname))

    function solve1(input::Vector{Int})
        push!(input, 0, maximum(input) + 3)
        input = sort(unique(input))
        diffs = diff(input)
        return sum(diffs .== 1) * sum(diffs .== 3)
    end

    function count_continuous_ones(Δ::Vector{Int})
        counts = Vector{Int}[]
        return string.(Δ) |> join |> x -> split(x, "3") |> x -> filter(y -> length(y) > 0, x) .|> length
    end

    function n_possible_steps(n::Int)
        if n == 1
            return 1
        elseif n == 2
            return 2
        elseif n == 3
            return 4
        else
            return n_possible_steps(n - 1) + n_possible_steps(n - 2) + n_possible_steps(n - 3)
        end
    end

    function solve2(input::Vector{Int})
        push!(input, 0, maximum(input) + 3)
        input = sort(unique(input))
        diffs = diff(input)
        return mapreduce(n_possible_steps, *, count_continuous_ones(diffs))
    end

    function main()
        input = parse_file(filename())
        sol1 = solve1(input)
        sol2 = solve2(input)
        @show sol1, sol2
    end

    main()
end

# Pablo Zubieta
function pablo() 
    input = parse.(Int, eachline(filename()))
    sort!(input)
    prepend!(input, 0)
    append!(input, last(input) + 3)

    # Part 1
    d = diff(input)
    @show count(==(1), d) * count(==(3), d)

    #Part 2
    # This is only because maximum(length, s) == 4 for my example and the examples given, so it's not general enough
    @show s = split(join(d), '3')
    @show 2^count(==("11"), s) * 4^count(==("111"), s) * 7^count(==("1111"), s)
end

# Sukera
function sukera()
    function solve2(input)
        diff(input) |>
            x -> mapreduce(string, *, x) |>
            x -> findall(r"1+", x) .|>
            length .|>
            tribonacci |>
            x -> reduce(*, x)
    end
    
    function tribonacci(n)
        n <= 1 && return 1  # 1x => 1, x => 1s
        n == 2 && return 2  # 11x => 1.(x+1), .2x
        return tribonacci(n-1) + tribonacci(n-2) + tribonacci(n-3)
    end

    data = parse.(Int, readlines(filename())) |> sort
    data = vcat(0, data, data[end]+3)
    @show solve2(data)

    diff(data) |> x -> mapreduce(string, *, x) |> x -> findall(r"1+", x) .|> length .|> tribonacci
end