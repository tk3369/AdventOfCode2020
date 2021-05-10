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

# Animation

using Luxor, Images

# Returns a new Luxor.Point location relative to `p`.
# The calculation of coordination requires the `radius` of hexagon.
# Additionally, a `shift` parameter can be provided to shift
# the calculated point in the 2D plane.
function cell_location(p::Point, radius::Float64, shift = Luxor.Point(0.0, 0.0))
    # First, move right (x-axis)
    θ = deg2rad(30)
    unit = 2 * radius * cos(θ)
    x = p.x * unit
    y = 0.0

    # Then, move up-left (z-axis)
    x -= -(p.z * (radius * cos(θ)))
    y -= -(p.z * (radius * sin(θ) + radius))
    return Luxor.Point(x, y) + shift
end

function draw_tile(
    point, radius, shift = Luxor.Point(0.0, 0.0); 
    stroke_color, fill_color
)
    sethue(fill_color)
    ngon(cell_location(point, radius, shift), radius, 6, π/2, :fill)
    sethue(stroke_color)
    ngon(cell_location(point, radius, shift), radius, 6, π/2, :stroke)
end

draw_white_tile(args...) = draw_tile(args...; stroke_color="white", fill_color="black")
draw_black_tile(args...) = draw_tile(args...; stroke_color="white", fill_color="red2")

# Create an animated gif.
# Each frame contains the steps and the final flipped tile of an instruction.
# Specify `max_frmaes` for quick experiementation with first few frames.
function create_animated_floor(
    w, h;
    dir = "/tmp/day24", frame_rate = 30, max_frames = typemax(Int)
)
    instruction_set = read_data()
    tiles = Dict{Point{Int},Int}()

    # I used an image size of 600x600 to determine font size & relative positions
    # So the `scale` variable can be used to adjust all size settings for a custom w x h image.
    scale = w / 600.0
    radius = 8scale

    image = buffer = zeros(UInt32, w, h)
    shift = Luxor.Point(0.0, 10scale)

    # clean output directory
    for file in readdir(dir; join = true)
        # @debug "Removing $file"
        rm(file)
    end

    # remember if a cell has been visited before
    visited = Set()
    
    for (i, instructions) in enumerate(instruction_set)
        Drawing(w, h, :png)
        # On first frame, put on title and footer
        if i == 1
            sethue("green1")
            fontsize(25scale)
            text("Merry Christmas!", Luxor.Point(w/2.0, 40scale), halign=:center)
            fontsize(12scale)
            text("Tom Kwong, Advent of Code (Day 24, 2020)", Luxor.Point(w/2.0, h - 10scale), halign=:center)
        end
        origin()
        point = Point(0, 0, 0)
        for direction in instructions
            point = step(point, direction)
            point ∈ visited && continue
            push!(visited, point)
            draw_white_tile(point, radius, shift) 
        end
        flip_tile!(tiles, point)
        if is_black(point, tiles)
            draw_black_tile(point, radius, shift)
        else
            draw_white_tile(point, radius, shift)
        end
        image = image_as_matrix!(buffer)
        finish()
        save("$(dir)/image-$(i).png", Images.RGB.(image))
        i > max_frames && break
    end
    run(`ffmpeg -framerate $(frame_rate) -f image2 -i $(dir)/image-%d.png -y $(dir)/floor.gif`)
end

# Draw a static floor image
function draw_floor()
    floor = prepare_floor()
    radius = 7.0
    @png begin
        background("black")
        for (point, color) in floor
            if color == 1
                draw_black_tile(point, radius)
            else
                draw_white_tile(point, radius)
            end
        end
    end
end
