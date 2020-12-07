const nums = parse.(Int, readlines("day01.txt"))

# Find two numbers that sum to 2020 and multiply them.
function part1(nums, target)
    set = Set{Int}()
    for v in nums
        complement = target - v
        complement in set && return complement * v
        push!(set, v)
    end
    return -1
end

part1(nums, 2020)

# Find three numbers that sum to 2020 and multiply them.
function part2(nums)
    for i in 1:length(nums)
        target = 2020 - nums[i]
        prod = part1(vcat(nums[1:i-1], nums[i+1:end]), target)
        prod > 0 && return nums[i] * prod
    end
    return -1
end

part2(nums)

# P.S. These are pretty much TwoSum and ThreeSum problems on LeetCode.
