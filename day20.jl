struct Tile
    id
    data
    orientation
    rotation
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
function hashes(t::Tile, n::Int)
    top, bottom, left, right = sides(t)
    if n == 0
        [hash(top), hash(bottom), hash(left), hash(right)]
    elseif n == 1
        [hash(right), hash(left), hash(reverse(top)), hash(reverse(bottom))]
    elseif n == 2
        [hash(reverse(bottom)), hash(reverse(top)), hash(reverse(right)), hash(reverse(left))]
    elseif n == 3
        [hash(reverse(left)), hash(reverse(right)), hash(bottom), hash(top)]
    else
        error("Incorrect usage")
    end
end

# Flip vertically
vflip(t::Tile) = Tile(
    t.id,
    vcat(t.data[end], t.data[2:end-1], t.data[1]),
    :vertical,
    t.rotation
)

# Flip horizontally
hflip(t::Tile) = Tile(
    t.id,
    [join(vcat(r[end], r[2:end], r[1])) for r in t.data],
    :horizontal,
    t.rotation
)

side(i::Int) = ["top   ", "bottom", "left  ", "right "][i]

# Match a tile against all other tiles.
# No need to transform current tile as long as we rotate/flip others. 
function match_tile(t::Tile, tiles::Dict)
    # @show "Matching tile $(t.id)"
    side_hashes = hashes(t, 0)
    matched = Set{Int}()
    for (j, sh) in enumerate(side_hashes)
        for candidate in values(tiles)
            t == candidate && continue
            for x in [candidate, hflip(candidate)] #, vflip(candidate)]
                for i in 0:3
                    csh = hashes(x, i)
                    idx = findfirst(==(sh), csh)
                    if idx !== nothing
                        # println("Matched side $(side(j)): $(x.id) $(x.orientation) rotation=$i")
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

# Given a tile `x`, align tile `y` by rotating/flipping `y`.
# Only need to align a single side, either :top or :left (of `y`)
# Return a new tile object transformed from `y`.
function align(x::Tile, y::Tile, side::Symbol)
    if side == :top
        x_bottom_hash = hashes(x, 0)[2]
        for y in [y, hflip(y), vflip(y)]
            for i in 0:3
                csh = hashes(y, i)[1]  # top hash
                if csh == x_bottom_hash
                    return Tile(y.id, y.data, y.orientation, i)
                end
            end
        end
    elseif side == :left
        x_right_hash = hashes(x, 0)[4]
        for y in [y, hflip(y), vflip(y)]
            for i in 0:3
                csh = hashes(y, i)[3]  # left hash
                if csh == x_right_hash
                    return Tile(y.id, y.data, y.orientation, i)
                end
            end
        end
    else
        error("Unknown side $side")
    end
end

function assemble(tiles::Dict, mappings::Dict)
    # create an image array
    sz = round(Int, sqrt(length(tiles)))
    image = fill(0, (sz, sz))

    # aligned tiles
    picture = Any[nothing for i in 1:sz, j in 1:sz]

    # pick a random corner and bootstrap the process
    corner = [k for (k,v) in mappings if length(v) == 2][1]
    neighbors = [v for v in mappings[corner]]

    @show image[1,1] = corner 
    @show image[2,1] = neighbors[1]
    @show image[1,2] = neighbors[2]

    picture[1,1] = tiles[corner]
    picture[2,1] = align(tiles[corner], tiles[neighbors[1]], :top)
    picture[1,2] = align(tiles[corner], tiles[neighbors[2]], :left)

    # use a Set to remember which tile has already been placed
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
            common_tile = intersect(mappings[left_tile], mappings[top_tile])
            common_tile = setdiff(common_tile, visited)
            @assert length(common_tile) == 1
            common_tile_id = pop!(common_tile)
            image[pos[1], pos[2]] = common_tile_id
            push!(visited, common_tile_id)
            picture[pos[1], pos[2]] = align(tiles[left_tile], tiles[common_tile_id], :left)
            # println("Found tile at row=$row i=$i pos=$pos => $common_tile_id")
        end
        # place tile at (row, 1). It has to be the only unvisited top neighbor's neighbors 
        if row <= sz
            # @show "Looking for left edge title"
            top_id = image[row - 1, 1]
            me = setdiff(mappings[top_id], visited)
            @assert length(me) == 1
            me_id = pop!(me)
            image[row, 1] = me_id
            push!(visited, me_id)
            picture[row, 1] = align(tiles[top_id], tiles[me_id], :top)
            # println("Found left edge tile ($(row), 1)=> $me_id")
        end
        # place tile at (1, row)
        if row <= sz
            # @show "Looking for top edge title"
            left_id = image[1, row - 1]
            me = setdiff(mappings[left_id], visited)
            @assert length(me) == 1
            me_id = pop!(me)
            image[1, row] = me_id
            push!(visited, me_id)
            picture[1, row] = align(tiles[left_id], tiles[me_id], :left)
            # println("Found top edge tile (1, $(row)) => $me_id")
        end
    end
    image, picture
end

function as_matrix(t::Tile)
    sz = length(t.data)
    return [r[j] == '#' ? 1 : 0 for (i,r) in enumerate(t.data), j in 1:sz]
end

function flip_matrix(A::AbstractMatrix{T}, orientation::Symbol) where T
    A = copy(A)
    if orientation == :horizontal
        return A[:, 1:end] = A[:, end:-1:1]
    elseif orientation == :vertical
        return A[1:end, :] = A[end:-1:1, :]
    else
        return A
    end
end

# n = 0, 1, 2, 3 (counter-clockwise)
function rotate_matrix(A::AbstractMatrix{T}, n::Int) where T
    m = (4 - n) % 4
    A = copy(A)
    for i in 1:m
        A = transpose(A)
        A[:, 1:end] = A[:, end:-1:1]
    end
    return A
end

function final_matrix(t::Tile)
    A = as_matrix(t)
    A = flip_matrix(A, t.orientation)
    A = rotate_matrix(A, t.rotation)
    return A
end

function make_bitmap(picture)
    final_matrix.(picture)
end

function part1()
    tiles = read_data("day20.txt")
    result = match_all(tiles)
    return prod([k for (k,v) in result if length(v) == 2])
end

# NOTE: Not finished yet... will come back to this later.
function part2()
    tiles = read_data("day20.txt")
    mappings = match_all(tiles)
    puzzle_ids, puzzle_picture = assemble(tiles, mappings)
    # return make_bitmap(puzzle_picture)
end
