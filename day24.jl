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

is_black(p::Point, tiles::AbstractDict) = get(tiles, p, -1) == 1
is_white(p::Point, tiles::AbstractDict) = !is_black(p, tiles)

function neighbors(p::Point)
    return (
        Point(p.x, p.y + 1, p.z - 1),
        Point(p.x, p.y - 1, p.z + 1),
        Point(p.x + 1, p.y - 1, p.z),
        Point(p.x - 1, p.y + 1, p.z),
        Point(p.x + 1, p.y, p.z - 1),
        Point(p.x - 1, p.y, p.z + 1),
    )
end

function num_adjacent_black_tiles(p::Point, tiles::AbstractDict)
    return sum(is_black(q, tiles) for q in neighbors(p))
end

me_and_neighbors(p::Point) = (p, neighbors(p)...)

black_tiles(tiles::AbstractDict) = (k for (k,v) in tiles if v == 1)

function candidates(tiles::AbstractDict)
    return Set(Iterators.flatten(me_and_neighbors(p) for p in black_tiles(tiles)))
end

function decorate!(tiles::AbstractDict)
    need_flip = Point[]
    for p in candidates(tiles)
        nb = num_adjacent_black_tiles(p, tiles)
        if (is_black(p, tiles) && (nb == 0 || nb > 2)) ||
           (is_white(p, tiles) && nb == 2)
            push!(need_flip, p)
        end
    end
    foreach(p -> flip_tile!(tiles, p), need_flip)
end

count_black_tiles(tiles) = tiles |> black_tiles |> collect |> length

part1() = count_black_tiles(prepare_floor())

function part2(n = 100)
    tiles = prepare_floor()
    foreach(_ -> decorate!(tiles), 1:n)
    return count_black_tiles(tiles)
end
