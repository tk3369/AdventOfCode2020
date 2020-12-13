filename() = "day13.txt"

earliest() = parse(Int, readlines(filename())[1])

buses() = parse.(Int, filter(x -> x != "x", split(readlines(filename())[2], ",")))

# Find the earliest time that I can take a bus, at or after time `target`.
# The buses departs at different but consistent times independently. The
# bus schedule is stored in an array of integers `bs`.
# 
# Algorithm:
#
# The next available departure time for each bus can be determined by 
# a simple formula: (target ÷ b + 1) * b
#
# Just loop through the buses and find the best one. Keep the best
# solution so far in two variables:
# 1. `ride`: which bus? Just an index into the `bs`.
# 2. `best`: best time to board that bus.
#
# Thoughts:
# This could be improved by some kind of `argmin` algorithm.
function part1()
    target = earliest()
    bs = buses()
    best = typemax(Int)
    ride = -1
    for (i, b) in enumerate(bs)
        next = ((target ÷ b) + 1) * b
        if next < best
            best = next
            ride = i
        end
    end
    return bs[ride] * (best - target)
end

# ------------------------------------------
#=
The meaning of the bus schedule input has changed.
- First line is no longer used
- The positions of second line's numbers represents a constraint about how much
  time they have to be aligned against the first bus.

Brute force algorithm (with some math intuition):

Start with the first and second bus. The intuition is that if the first bus departs
at a multiple of `x`, then we must solve a `y` such that the second bus departs at
that time and yet it's exactly `z` minutes after. For example:

    3x + z = 5y  (x_id=3, y_id=5, z=1)

So we can write a function that is given a value of `x`, we can find the *next*
`x` & `y` value such that the equation still holds.
=#
function search_xy(apart, x_id, y_id, x)
    while true
        x += 1
        y, rem = divrem(apart + x_id * x, y_id)
        rem == 0 && return x, y
    end
end

#=
Now, it turns out that the next `x`'s are predictable. In the same example above,
the values are (x,y)'s are as follows:

julia> search_xy(1, 3, 5, 0)
(3, 2)

julia> search_xy(1, 3, 5, 3)
(8, 5)

julia> search_xy(1, 3, 5, 8)
(13, 8)

So it's clear that the value of `x` increments by 5 every time. Hence, once we 
have bootstrapped the first candidate value of `x`, the following values are
readily available.

Given these information, the algorithm works as follows:
1. Find the first 

=#
read_buses2() = [(pos = i - 1, val = parse(Int, v))
    for (i,v) in enumerate(split(readlines(filename())[2], ",")) if v != "x"]

function part2(atleast=1)
    schedule = read_buses2()
    buses = [s.val for s in schedule]
    apart = diff([s.pos for s in schedule])

    # Find a sensible starting point for first bus such that there's a solution
    # for second bus.
    main_start, _ = search_xy(apart[1], buses[1], buses[2], atleast)

    # The increment for first bus is just the cycle time for second bus according
    # to our math intution above.
    incr = buses[2]

    iter = 0
    while true
        start = main_start
        n = length(buses) - 1
        for i in 1:n
            x = buses[i] * start + apart[i]
            d, r = divrem(x, buses[i+1])
            if r == 0 && i == n  # no remainder all along?
                return main_start * buses[1]
            elseif r != 0        # has remainder, not a solution
                break
            end
            start = d            # starting point for next bus
        end
        iter += 1
        main_start += incr
        # iter > 30 && break     # circut breaking for debugging purpose
    end
end

# https://shainer.github.io/crypto/math/2017/10/22/chinese-remainder-theorem.html

function chinese_remainder_gauss(n, a)
    N = prod(n)
    result = 0
    for i in 1:length(n)
        ai = a[i]
        ni = n[i]
        bi = N ÷ ni
        result += ai * bi * invmod(bi, ni)
    end
    return result % N
end

function part2_chinese_remainder()
    schedule = read_buses2()
    a = [i == 0 ? 0 : v.val - v.pos for (i,v) in enumerate(schedule)]
    n = [v.val for v in schedule]
    return chinese_remainder_gauss(n, a)
end
