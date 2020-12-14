filename() = "day14.txt"

#=
Read data into tuples of commands.

Example:
julia> read_data()
4-element Array{NamedTuple,1}:
 (command = :setmask, value = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X", 
        setter = [2 => 0, 7 => 1])
 (command = :assign, address = "8", value = 11)
 (command = :assign, address = "7", value = 101)
 (command = :assign, address = "8", value = 0)
=#
function read_data()
    function parse_command(line)
        left, right = split(line, " = ")
        if left == "mask"
            right_reversed = reverse(right)
            bit_positions = findall(in(['0','1']), right_reversed)
            bit_setter = [p => parse(Int, right_reversed[p]) for p in bit_positions]
            (command = :setmask, value = right, setter = bit_setter)
        else
            address = match(r"mem\[(.*)\]", left).captures[1]
            (command = :assign, address = address, value = parse(Int, right))
        end
    end
    lines = readlines(filename())
    return parse_command.(lines)
end

"""
Set a specific bit at `pos` position (counting from right)
for the value.  The `bit` may be 1 or 0. Returning the result
as a decimal value.
"""
function setbit(value::Int, pos::Int, bit)
    str = bitstring(value)
    rpos = 64 - pos + 1
    return parse(Int, string(str[1:rpos-1], "$bit", str[rpos+1:end]); base = 2)
end

"""
Apply bitmask to a value. The `setter` argument contains an array of
pairs. Each pair is interpreted as pos => bit.
"""
function apply_bitmask(val::Int, setter)
    for s in setter
        val = setbit(val, first(s), last(s))
    end
    return val
end

"""
Execute the program.
- For bitmask command, save a reference of the setter.
- For assign command, take the value and apply bitmasks, then assign to memory.
"""
function part1()
    program = read_data()
    local setter
    mem = Dict()
    for instruction in program
        if instruction.command == :setmask
            setter = instruction.setter
        else
            mem[instruction.address] = apply_bitmask(instruction.value, setter)
        end
    end
    return sum(values(mem))
end

"""
Read data for part 2. This is needed because part2 interprets the instructions
differently:
- '1': set bit
- '0': ignore
- 'X': floater

The `:setmask` instruction now contains a new `floater` property, which contains
the positions where the bit floats. 
"""
function read_data2()
    function parse_command(line)
        left, right = split(line, " = ")
        if left == "mask"
            right_reversed = reverse(right)
            setter = [i => c for (i,c) in enumerate(right_reversed) if c == '1']
            floater = findall(==('X'), right_reversed)
            (command = :setmask, value = right, setter = setter, floater = floater)
        else
            address = match(r"mem\[(.*)\]", left).captures[1]
            (command = :assign, address = parse(Int, address), value = parse(Int, right))
        end
    end
    lines = readlines("day14.txt")
    return parse_command.(lines)
end

# Make a new setter
# Arguments:
# - `floater`: an array of bit positions
# - `tup`: tuple of bit combinations
make_setter(floater, tup) =[floater[i] => tup[i] for i in 1:length(floater)]

function part2()
    program = read_data2()
    local setter, floater
    mem = Dict{Int,Int}()
    for instruction in program
        if instruction.command == :setmask
            setter = instruction.setter
            floater = instruction.floater
        else
            temp_address = apply_bitmask(instruction.address, setter)
            for bit_tuple in Iterators.product([[0,1] for _ in 1:length(floater)]...)
                addr = apply_bitmask(temp_address, make_setter(floater, bit_tuple))
                mem[addr] = instruction.value
            end
        end
    end
    return sum(values(mem)), mem
end

# Visualization
using Plots

function part2_animated(board_size = 261550)
    anim = Animation()
    marker_size = 2.0
    marker_alpha = 0.8
    marker_color = :green
    marker_shape = :rect
    scatter([1],[1], xlims = (1, board_size), ylims = (1, board_size),
        markercolor = marker_color,
        markersize = marker_size,
        markeralpha = marker_alpha,
        markershape = marker_shape,
        markerstrokewidth = 0,
        legend = nothing, ticks = nothing, showaxis = false, grid = nothing,
        background_color = :black,
        foreground_color_axis = :black, gridlinewidth = 0)
    program = read_data2()
    local setter, floater
    mem = Dict{Int,Int}()
    cnt = 0
    xs = Int[]
    ys = Int[]
    for instruction in program
        if instruction.command == :setmask
            setter = instruction.setter
            floater = instruction.floater
        else
            temp_address = apply_bitmask(instruction.address, setter)
            for bit_tuple in Iterators.product([[0,1] for _ in 1:length(floater)]...)
                addr = apply_bitmask(temp_address, make_setter(floater, bit_tuple))
                mem[addr] = instruction.value
                x, y = addr ÷ board_size, addr % board_size
                push!(xs, x)
                push!(ys, y)
            end
        end
        cnt += 1
        if cnt % 5 == 0
            scatter!(xs, ys, 
                markercolor = marker_color,
                markersize = marker_size,
                markeralpha = marker_alpha,
                markershape = marker_shape,
                markerstrokewidth = 0,
                title = "AoC Day 14 - Iteration $cnt")
            frame(anim)
            resize!(xs, 0)
            resize!(ys, 0)
        end
    end
    scatter!(xs, ys, 
        markercolor = marker_color,
        markersize = marker_size,
        markeralpha = marker_alpha,
        markershape = marker_shape,
        markerstrokewidth = 0,
        title = "AoC Day 14 - Iteration $cnt")
    frame(anim)
    gif(anim, "day14_anim.gif", fps = 15)
end
