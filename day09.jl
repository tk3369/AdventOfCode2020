filename() = "day09.txt"

read_data() = parse.(Int, readlines(filename()))

# read_data() = parse.(Int, split("""35
# 20
# 15
# 25
# 47
# 40
# 62
# 55
# 65
# 95
# 102
# 117
# 150
# 182
# 127
# 219
# 299
# 277
# 309
# 576""", "\n"))

function part1(pre)
    v = read_data()
    for i in pre+1:length(v)
        twosum(v[i-pre:i-1], v[i]) || return v[i]
    end
end

function twosum(nums, target)
    # @info "Checking $target: $nums"
    set = Set{Int}()
    for v in nums
        complement = target - v
        complement in set && return true
        push!(set, v)
    end
    return false
end

# part 1
# part1(25) # 41682220

# part 2 

function part2_brute_force(v, target)
    for i in 1:length(v)
        for j in i:length(v)
            sum(v[i:j]) == target && return i, j, sum(extrema(v[i:j]))
        end
    end
    return -1
end

function part2(v, target)
    i = 1
    j = 2
    s = v[i] + v[j]
    while j < length(v)
        if s < target
            j += 1
            s += v[j]
        elseif s > target
            s -= v[i]
            i += 1
        else
            return i, j , sum(extrema(v[i:j]))
        end
    end
    return -1
end

function part2()
    v = read_data()
    part2(v, 41682220)
end

#= 
Brute force is very slow.

julia> @time part2(read_data(), 41682220)
  0.000209 seconds (2.02 k allocations: 72.328 KiB)
(422, 438, 5388976)

julia> @time part2_brute_force(read_data(), 41682220)
  0.181522 seconds (334.63 k allocations: 1.049 GiB, 33.86% gc time)
(422, 438, 5388976)
=#

