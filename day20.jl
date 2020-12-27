struct Tile{T <: AbstractString}
    id::Int
    data::Vector{T}
    orientation::Symbol
    rotation::Int
end

function Base.show(io::IO, t::Tile)
    print(io, "$(t.id),$(t.orientation),$(t.rotation)")
end

function read_data(filename)
    blocks = split(String(read(filename)), "\n\n")
    function parse_block(block)
        lines = split(block, "\n")
        id = parse(Int, match(r"Tile (\d+):", lines[1]).captures[1])
        data = lines[2:end]
        return id, data, :original, 0
    end
    tiles = [Tile(parse_block(block)...) for block in blocks]
    return Dict(t.id => t for t in tiles)
end

sides(t::Tile) = let len = length(t.data)
    top = t.data[1]
    bottom = t.data[end]
    left = join([t.data[i][1] for i ∈ 1:len])
    right = join([t.data[i][end] for i ∈ 1:len])
    top, bottom, left, right
end

# n = 0, 1, 2, 3 (rotating left by 90 degrees)
# Pass n as -1 to use the tile's own rotation setting
function hashes(t::Tile, n::Int = -1, orientation::Symbol = :original)
    the_tile = if orientation == :original
        t
    elseif orientation == :horizontal
        hflip(t)
    else
        vflip(t)
    end
    top, bottom, left, right = sides(the_tile)
    rotation = n >= 0 ? n : the_tile.rotation
    if rotation == 0
        [hash(top), hash(bottom), hash(left), hash(right)]
    elseif rotation == 1
        [hash(right), hash(left), hash(reverse(top)), hash(reverse(bottom))]
    elseif rotation == 2
        [hash(reverse(bottom)), hash(reverse(top)), hash(reverse(right)), hash(reverse(left))]
    elseif rotation == 3
        [hash(reverse(left)), hash(reverse(right)), hash(bottom), hash(top)]
    else
        error("Incorrect usage")
    end
end

# Flip vertically
vflip(t::Tile) = Tile(
    t.id,
    t.data[end:-1:1],
    :vertical,
    t.rotation
)

# Flip horizontally
hflip(t::Tile) = Tile(
    t.id,
    [reverse(r) for r in t.data],
    :horizontal,
    t.rotation
)

# Match a tile against all other tiles.
# No need to transform current tile as long as we rotate/flip others. 
function match_tile(t::Tile, tiles::Dict)
    # @show "Matching tile $(t.id)"
    side_hashes = hashes(t, 0)
    matched = Set{Int}()
    for (j, sh) in enumerate(side_hashes)
        for candidate in values(tiles)
            t == candidate && continue  # skip myself
            for x in [candidate, hflip(candidate), vflip(candidate)]
                for i in 0:3
                    csh = hashes(x, i)
                    idx = findfirst(==(sh), csh)
                    if idx !== nothing
                        push!(matched, x.id)
                    end
                end
            end
        end
    end
    return matched
end

function match_all(tiles::Dict)
    return Dict(tile.id => match_tile(tile, tiles) for tile in values(tiles))
end

# Given a tile `x`, try to fit tile `y` by rotating/flipping `y`.
# Only need to fit `y` by aligning its top or left to `x`.
# Return the orientation and rotatiion values once it's fitted.
function fit(x::Tile, y::Tile, side::Symbol)
    if side == :top
        x_bottom_hash = hashes(x, x.rotation, x.orientation)[2]
        # x.id == 2213 && @info "x (2213)" x hashes(x)
        for (orientation, this_y) in zip([:original, :horizontal, :vertical], [y, hflip(y), vflip(y)])
            for rotation in 0:3
                csh = hashes(this_y, rotation)[1]  # top hash
                # x.id == 2213 && @info "this_y ($(y.id))" hashes(this_y, i)
                if csh == x_bottom_hash
                    return orientation, rotation
                end
            end
        end
    elseif side == :left
        x_right_hash = hashes(x, x.rotation, x.orientation)[4]
        # x.id == 1021 && @info "x (1021)" x hashes(x)
        for (orientation, this_y) in zip([:original, :horizontal, :vertical], [y, hflip(y), vflip(y)])
            for rotation in 0:3
                csh = hashes(this_y, rotation)[3]  # left hash
                if csh == x_right_hash
                    return orientation, rotation
                end
            end
        end
    end
    return nothing
end

# Align `y` against `x` on a specific `side`.
# Return a new Tile object transformed from `y`.
# The tile `y` in `tiles` is mutated to the new orientation.
function align!(tiles::Dict, x::Tile, y::Tile, side::Symbol)
    result = fit(x, y, side)
    if result !== nothing
        orientation, rotation = result
        oriented_tile = Tile(y.id, y.data, orientation, rotation)
        tiles[y.id] = oriented_tile
        return oriented_tile
    end
    return nothing
end

# Assemble the puzzle!
# Since we don't know which corner piece is the top-left one,
# and our algorithm requires to start from top-left, we can
# just try all corner pieces.
function assemble(tiles::Dict, mappings::Dict)
    corners = [k for (k,v) in mappings if length(v) == 2]
    for c in corners
        image, picture = try_assemble(tiles, mappings, c)
        if count(isnothing, picture) == 0
            return image, picture
        end
    end
    error("Too bad, cannot assemble the puzzle")
end

# Bootstrap the assembly process by taking a corner piece and
# figure out how it should be oriented, and then properly 
# match its adjacent pieces.
function bootstrap(tiles::Dict, mappings::Dict, corner::Int)
    tile = tiles[corner]
    n1, n2 = [tiles[id] for id in mappings[corner]]
    for t in (tile, hflip(tile), vflip(tile))
        for rotation in 0:3
            r1 = fit(tile, n1, :top)
            if r1 !== nothing  # good fit for (1,1) and (2,1)
                good_corner = Tile(tile.id, tile.data, t.orientation, rotation)
                good_bottom = Tile(n1.id, n1.data, r1[1], r1[2])
                r2 = fit(tile, n2, :left)
                good_right = Tile(n2.id, n2.data, r2[1], r2[2])
                return good_corner, good_bottom, good_right
            end
        end
    end
    return nothing
end

#=
Try to assemble the puzzle using the specified top-left `corner` piece.

The algorithm works as follows:
1. Align the top-left corner piece (1,1) and its adjacent pieces (2,1) & (1,2)
2. Assemble pieces in a diagonal manner (from lower left to upper right)
   - the left-edge piece can be aligned with its top neighbor
   - the middle pieces can be aligned with both its top & left neighbors
   - the top-edge piece can be aligned with its left neighbor

The loop index is designed to go out of bound due to the diagonal sweeping
process. The if-conditions are are used to skip out-of-bound cells.

Returns a tuple with these elements:
1. `image` - a matrix of tile id's
2. `picture` - a matrix of tiles
=#
function try_assemble(tiles::Dict, mappings::Dict, corner::Int)
    # create an image array
    sz = round(Int, sqrt(length(tiles)))
    image = fill(0, (sz, sz))

    # aligned tiles
    picture = Matrix{Tile}(undef, (sz, sz))

    # Bootstrap and align the 3 top-left pieces
    top_left_pieces = bootstrap(tiles, mappings, corner)
    picture[1,1], picture[2,1], picture[1,2] = top_left_pieces
    image[1,1], image[2,1], image[1,2] = getproperty.(top_left_pieces, :id)

    # Mutate the tiles
    tiles[image[1,1]] = top_left_pieces[1]
    tiles[image[2,1]] = top_left_pieces[2]
    tiles[image[1,2]] = top_left_pieces[3]

    # Use a Set to remember which tile has already been placed
    visited = union(corner, mappings[corner])

    for row in 3:(2sz-1) # intentionally go out of bound for the diagnoal swipe
        pos = (row, 1)
        for i in 1:row-2   # discount 2 edge tiles
            pos = (pos[1]-1, pos[2]+1) # move up-right
            if pos[1] > sz || pos[2] > sz
                continue  # skip out of bound imaginary space
            end
            left = (pos[1], pos[2]-1)  # left neighbor (col - 1)
            top  = (pos[1]-1, pos[2])  # top neighbor (row - 1)
            # @show pos left top
            left_tile = image[left[1], left[2]]
            top_tile = image[top[1], top[2]]
            me = intersect(mappings[left_tile], mappings[top_tile])
            me = setdiff(me, visited)
            @assert length(me) == 1
            me_id = pop!(me)
            image[pos[1], pos[2]] = me_id
            push!(visited, me_id)
            picture[pos[1], pos[2]] = align!(tiles, tiles[left_tile], tiles[me_id], :left)
            # println("Found tile at row=$row i=$i pos=$pos => $me_id")
        end
        # place tile at (row, 1). It has to be the only unvisited top neighbor's neighbors 
        if row <= sz
            top_id = image[row - 1, 1]
            # @show "Looking for top edge title" row top_id visited
            me = setdiff(mappings[top_id], visited)
            @assert length(me) == 1
            me_id = pop!(me)
            image[row, 1] = me_id
            push!(visited, me_id)
            picture[row, 1] = align!(tiles, tiles[top_id], tiles[me_id], :top)
            # println("Found left edge tile ($(row), 1)=> $me_id")
        end
        # place tile at (1, row)
        if row <= sz
            # @show "Looking for left edge title"
            left_id = image[1, row - 1]
            me = setdiff(mappings[left_id], visited)
            @assert length(me) == 1
            me_id = pop!(me)
            image[1, row] = me_id
            push!(visited, me_id)
            picture[1, row] = align!(tiles, tiles[left_id], tiles[me_id], :left)
            # println("Found top edge tile (1, $(row)) => $me_id")
        end
    end
    return image, picture
end

function matrix(t::Tile)
    sz = length(t.data)
    return [r[j] == '#' ? 1 : 0 for (i,r) in enumerate(t.data), j in 1:sz]
end

function flipped(A::AbstractMatrix{T}, orientation::Symbol) where T
    A = copy(A)
    if orientation == :horizontal
        return A[:, 1:end] = A[:, end:-1:1]
    elseif orientation == :vertical
        return A[1:end, :] = A[end:-1:1, :]
    else
        return A
    end
end

# Generally, rotating a matrix *clockwise* involves two steps:
# 1. transpose the matrix
# 2. flip the columns
#
# Convention: n = 0, 1, 2, 3 (counter-clockwise)
function rotated(A::AbstractMatrix{T}, n::Int) where T
    # adjust number of rotations since we're doing counter-clockwise
    m = (4 - n) % 4
    A = copy(A)
    for i in 1:m
        A = transpose(A)
        A[:, 1:end] = A[:, end:-1:1]
    end
    return A
end

# Return a bitmap matrix for the tile that is flipped/rotated accordingly.
function oriented(t::Tile)
    A = matrix(t)
    A = flipped(A, t.orientation)
    A = rotated(A, t.rotation)
    return A
end

# Get rid of the border of a bitmap matrix.
remove_border(A::AbstractMatrix) = A[2:end-1,2:end-1]

# Making a bitmap for a picture (2D array of tiles)
function make_bitmap(picture)
    M = remove_border.(oriented.(picture))
    return vcat([hcat(M[r, :]...) for r in 1:size(picture,1)]...)
end

# Parse a monster stencil as a bitmap array
function monster_stencil()
    str =   """
                  # 
#    ##    ##    ###
 #  #  #  #  #  #   """
    parse_line(s) = [c == ' ' ? 0 : 1 for c in s]
    vcat(map(transpose, parse_line.(split(str, "\n")))...)
end

# Check if the specific location at `A[row,col]` (top-left)
# contains a monster image. Apply the stencil using bitwise-and
# operation and see if the result contains the same number of 1's
# as in the stencil.
function is_monster(stencil, A, row, col)
    r, c = size(stencil)
    area = A[row:row+r-1, col:col+c-1]
    masked_area = stencil .& area
    return sum(masked_area) == sum(stencil)
end

# Find all monsters in a bitmap. Return the locations of those
# monsters (top-left position)
function find_monsters(stencil, bitmap)
    br, bc = size(bitmap)
    sr, sc = size(stencil)
    locations = []
    for i in 1:br-sr+1
        for j in 1:bc-sc+1
            if is_monster(stencil, bitmap, i, j)
                # @info "Found monster: bitmap=$(hash(bitmap)) i=$i j=$j"
                push!(locations, (i,j))
            end
        end
    end
    return locations
end

# Mark the monsters on the bitmap with a value of 2.
function mark_monsters!(stencil, bitmap, locations)
    for loc in locations
        for row in 1:size(stencil, 1)
            for col in 1:size(stencil, 2)
                if stencil[row, col] == 1
                    bitmap[loc[1] + row - 1, loc[2] + col - 1] = 2
                end
            end
        end
    end
end

# Flip and rotate the bitmap and see if we can locate any monster.
# If so, just return the new bitmap and the locations of monsters.
function orient_and_find_monsters(stencil, bitmap)
    for bm in (bitmap, flipped(bitmap, :horizontal), flipped(bitmap, :vertical))
        for rotation in 0:3
            bm2 = rotated(bm, rotation)
            locations = find_monsters(stencil, bm2)
            if length(locations) > 0
                # @info "Found monster in bitmap=$(hash(bm2))"
                return bm2, locations
            end
        end
    end
    error("can't find any monsters :-(")
end

function part1()
    tiles = read_data("day20.txt")
    result = match_all(tiles)
    return prod([k for (k,v) in result if length(v) == 2])
end

function part2()
    tiles = read_data("day20.txt")
    mappings = match_all(tiles)
    # @info "mappings" mappings
    puzzle_ids, puzzle_picture = assemble(tiles, mappings)
    
    bitmap = make_bitmap(puzzle_picture)
    stencil = monster_stencil()

    bitmap, locations = orient_and_find_monsters(stencil, bitmap)

    mark_monsters!(stencil, bitmap, locations)
    return count(==(1), bitmap)
end

