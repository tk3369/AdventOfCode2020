const magic = 20201227

function transform(subject_number, loop_size)
    v = 1
    for i in 1:loop_size
        v *= subject_number
        v %= magic
    end
    return v
end

function find_loop_size(subject_number, target)
    v = 1
    i = 1
    while true
        v *= subject_number
        v %= magic
        v == target && return i
        i += 1
    end
end

function part1()
    card_loop_size = find_loop_size(7, 12092626)
    door_loop_size = find_loop_size(7, 4707356)
    transform(12092626, door_loop_size)
end

# No part2 :-) I had to finish Day 20 to get the final golden star!
