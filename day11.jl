parse(lines) = split.(lines, "")

# read_data() = parse.(Int, readlines("day11.txt"))
read_data() = parse(readlines("day11.txt"))
# read_data() = parse(readlines("day11_sample1.txt"))

is_occupied(data,x,y) = data[x][y] == "#"
Base.isempty(data,x,y) = data[x][y] == "L"

rows(data) = length(data)
cols(data) = length(data[1])

function occupied_nearby(data, x, y)
    let rows = rows(data), cols = cols(data)
        n  = ((x - 1) >= 1 && is_occupied(data, x - 1, y))
        nw = ((x - 1) >= 1 && (y - 1) >= 1 && is_occupied(data, x - 1, y - 1))
        w  = ((y - 1) >= 1 && is_occupied(data, x, y - 1))
        sw = ((y - 1) >= 1 && (x + 1) <= rows && is_occupied(data, x + 1, y - 1))
        s  = ((x + 1) <= rows && is_occupied(data, x + 1, y))
        se = ((x + 1) <= rows && (y + 1) <= cols && is_occupied(data, x + 1, y + 1))
        e  = ((y + 1) <= cols && is_occupied(data, x, y + 1))
        ne = ((x - 1) >= 1 && (y + 1) <= cols && is_occupied(data, x - 1, y + 1))
        return n + nw + w + sw + s + se + e + ne
    end
end

function printdata(data)
    for r in 1:rows(data)
        for c in 1:cols(data)
            print(data[r][c])
        end
        println()
    end
end

function part1()
    data = read_data()
    h = UInt(0)
    cnt = 1
    while hash(data) != h
        h = hash(data)
        rule1 = [occupied_nearby(data,r,c) == 0 && isempty(data,r,c) for r in 1:rows(data), c in 1:cols(data)]
        rule2 = [occupied_nearby(data,r,c) >= 4 && is_occupied(data,r,c) for r in 1:rows(data), c in 1:cols(data)]
        for r in 1:rows(data), c in 1:cols(data)
            if isempty(data,r,c) && rule1[r,c]
                data[r][c] = "#"
            elseif is_occupied(data,r,c) && rule2[r,c]
                data[r][c] = "L"
            end
        end
        cnt += 1
    end
    count(is_occupied(data,r,c) for r in 1:rows(data), c in 1:cols(data))
end

# Part 2

function visible_occupied_seats(data, x, y)
    function trace(x, y, dx, dy, first=false)
        (x < 1 || y < 1 || x > rows(data) || y > cols(data)) && return 0
        if !first && isempty(data, x, y)
            # @info "found empty seat $x $y"
            return 0   # empty seat obstructs occupied seat
        elseif !first && is_occupied(data, x, y)
            # @info "found occupied seat $x $y"
            return 1
        else 
            return trace(x + dx, y + dy, dx, dy, false)  # keep looking
        end
    end
    # trace(x, y, -1, 0, true)
    sum(trace(x, y, dx, dy, true) for dx in [-1, 0, 1], dy in [-1, 0, 1] if !(dx == 0 && dy == 0))
end

function part2()
    data = read_data()
    h = UInt(0)
    cnt = 1
    while hash(data) != h
        h = hash(data)
        rule1 = [visible_occupied_seats(data,r,c) == 0 && isempty(data,r,c) for r in 1:rows(data), c in 1:cols(data)]
        rule2 = [visible_occupied_seats(data,r,c) >= 5 && is_occupied(data,r,c) for r in 1:rows(data), c in 1:cols(data)]
        for r in 1:rows(data), c in 1:cols(data)
            if isempty(data,r,c) && rule1[r,c]
                data[r][c] = "#"
            elseif is_occupied(data,r,c) && rule2[r,c]
                data[r][c] = "L"
            end
        end
        # printdata(data)
        cnt += 1
    end
    count(is_occupied(data,r,c) for r in 1:rows(data), c in 1:cols(data))
end

# Animation

using Plots, ColorSchemes

mapper(x) = x == "L" ? 0.5 : (x == "#" ? 1.0 : 0)

create_matrix(data) = [mapper(data[x][y]) for x in 1:rows(data), y in 1:cols(data)]

make_heatmap(A, i, scale = 5) = heatmap(A, size = size(A).*scale, 
    legend=false, ticks=:none, c=:winter, title="AoC Day 11 - Iteration $i")

function part1_animated()
    data = read_data()
    h = UInt(0)
    cnt = 1
    anim = Animation()
    while hash(data) != h
        h = hash(data)
        make_heatmap(create_matrix(data), cnt, 5)
        frame(anim)
        rule1 = [occupied_nearby(data,r,c) == 0 && isempty(data,r,c) for r in 1:rows(data), c in 1:cols(data)]
        rule2 = [occupied_nearby(data,r,c) >= 4 && is_occupied(data,r,c) for r in 1:rows(data), c in 1:cols(data)]
        for r in 1:rows(data), c in 1:cols(data)
            if isempty(data,r,c) && rule1[r,c]
                data[r][c] = "#"
            elseif is_occupied(data,r,c) && rule2[r,c]
                data[r][c] = "L"
            end
        end
        cnt += 1
    end
    gif(anim, "day11_anim.gif", fps = 10)
    count(is_occupied(data,r,c) for r in 1:rows(data), c in 1:cols(data))
end

# Stencil idea

# using OffsetArrays

# function parse_with_pad(file)
#     lines = readlines(file)
#     rows = length(lines)
#     cols = length(lines[1])
#     A = fill('.', (rows+2, cols+2))
#     for r in 1:rows
#         for c in 1:cols
#             A[r+1,c+1] = lines[r][c]
#         end
#     end
#     return OffsetArray(A, 0:rows+1, 0:cols+1)
# end

# function occupied_nearby_using_stencil(data, x, y)
#     stencil = [(-1, -1), (1, 1), (-1, 1), (1, -1), (0, 1), (1, 0), (0, -1), (-1, 0)]
#     delta = CartesianIndex.(stencil)
#     origin = CartesianIndex(x, y)
#     return sum(data[origin + d] == '#' for d in delta)
# end
