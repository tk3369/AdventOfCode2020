using Dates

filename() = "day24.txt"

# Cube coordindate system
# https://www.redblobgames.com/grids/hexagons/#coordinates-cube
struct Point{T}
    x::T
    y::T
    z::T
end

# Move a single step
function step(p::Point, direction::AbstractString)
    direction == "e"  && return Point(p.x+1, p.y-1, p.z)
    direction == "ne" && return Point(p.x+1, p.y, p.z-1)
    direction == "nw" && return Point(p.x, p.y+1, p.z-1)
    direction == "w"  && return Point(p.x-1, p.y+1, p.z)
    direction == "sw" && return Point(p.x-1, p.y, p.z+1)
    direction == "se" && return Point(p.x, p.y-1, p.z+1)
    error("Unknown direction")
end

function read_data()
    regex = r"(e|se|sw|w|nw|ne)"
    return [collect(m.match for m in eachmatch(regex, line)) 
        for line in readlines(filename())]
end

# Flip a single tile
function flip_tile!(tiles::AbstractDict, point::Point)
    if haskey(tiles, point)
        tiles[point] = -tiles[point]   # flip
    else
        tiles[point] = 1  # black
    end
end

# Initialize the tiles by flipping certain ones to black
function prepare_floor()
    instruction_set = read_data()
    tiles = Dict{Point{Int},Int}()
    for instructions in instruction_set
        point = foldl(step, instructions; init = Point(0, 0, 0))
        flip_tile!(tiles, point)
    end
    return tiles
end

is_black(p::Point, tiles::AbstractDict) = get(tiles, p, nothing) == 1
is_white(p::Point, tiles::AbstractDict) = !is_black(p, tiles)

# Determine the size of the hex grid that needs to be examined
function span(itr, field::Symbol)
    start, finish = extrema(getfield(p, field) for p in itr)
    return range(start - 1, finish + 1, step = 1)
end

function num_adjacent_black_tiles(p::Point, tiles::AbstractDict)
    is_black(Point(p.x, p.y + 1, p.z - 1), tiles) +
    is_black(Point(p.x, p.y - 1, p.z + 1), tiles) +
    is_black(Point(p.x + 1, p.y - 1, p.z), tiles) +
    is_black(Point(p.x - 1, p.y + 1, p.z), tiles) +
    is_black(Point(p.x + 1, p.y, p.z - 1), tiles) +
    is_black(Point(p.x - 1, p.y, p.z + 1), tiles)
end

num_black_tiles(tiles::AbstractDict) = count(==(1), values(tiles))

function decorate!(tiles::AbstractDict)
    ks = keys(tiles)
    need_flip = Point[]
    for x in span(ks, :x), y in span(ks, :y), z in span(ks, :z)
        p = Point(x, y, z)        
        nb = num_adjacent_black_tiles(p, tiles)
        if (is_black(p, tiles) && (nb == 0 || nb > 2)) ||
           (is_white(p, tiles) && nb == 2)
            push!(need_flip, p)
        end
    end
    foreach(p -> flip_tile!(tiles, p), need_flip)
end

part1() = num_black_tiles(prepare_floor())

function part2()
    tiles = prepare_floor()
    for i in 1:100
        decorate!(tiles)
        println(now(), " day ", i, ": ", num_black_tiles(tiles))
    end    
end
