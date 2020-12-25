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
    # vcat(t.data[end], t.data[2:end-1], t.data[1]),
    t.data[end:-1:1],
    :vertical,
    t.rotation
)

# Flip horizontally
hflip(t::Tile) = Tile(
    t.id,
    # [join(vcat(r[end], r[2:end], r[1])) for r in t.data],
    [reverse(r) for r in t.data],
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
# The original tiles is updated to the new orientitation.
function align!(tiles::Dict, x::Tile, y::Tile, side::Symbol)
    if side == :top
        x_bottom_hash = hashes(x, x.rotation, x.orientation)[2]
        # x.id == 2213 && @info "x (2213)" x hashes(x)
        for (orientation, this_y) in zip([:original, :horizontal, :vertical], [y, hflip(y), vflip(y)])
            for i in 0:3
                csh = hashes(this_y, i)[1]  # top hash
                # x.id == 2213 && @info "this_y ($(y.id))" hashes(this_y, i)
                if csh == x_bottom_hash
                    tiles[y.id] = Tile(y.id, y.data, orientation, i)
                    return tiles[y.id] 
                end
            end
        end
    elseif side == :left
        x_right_hash = hashes(x, x.rotation, x.orientation)[4]
        # x.id == 1021 && @info "x (1021)" x hashes(x)
        for (orientation, this_y) in zip([:original, :horizontal, :vertical], [y, hflip(y), vflip(y)])
            for i in 0:3
                csh = hashes(this_y, i)[3]  # left hash
                if csh == x_right_hash
                    tiles[y.id] = Tile(y.id, y.data, orientation, i)
                    return tiles[y.id] 
                end
            end
        end
    else
        error("Unknown side $side")
    end
end

function assemble(tiles::Dict, mappings::Dict)
    corners = [k for (k,v) in mappings if length(v) == 2]
    for c in corners
        image, picture, tiles = try_assemble(tiles, mappings, c)
        if count(isnothing, picture) == 0
            return image, picture, tiles
        end
    end
    error("Too bad, cannot assemble the puzzle")
end

function try_assemble(tiles::Dict, mappings::Dict, corner::Int)
    # create an image array
    sz = round(Int, sqrt(length(tiles)))
    image = fill(0, (sz, sz))

    # aligned tiles
    picture = Any[nothing for i in 1:sz, j in 1:sz]

    neighbors = [v for v in mappings[corner]]

    image[1,1] = corner 
    image[2,1] = neighbors[1]
    image[1,2] = neighbors[2]

    picture[1,1] = tiles[corner]
    picture[2,1] = align!(tiles, tiles[corner], tiles[neighbors[1]], :top)
    picture[1,2] = align!(tiles, tiles[corner], tiles[neighbors[2]], :left)

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
            picture[pos[1], pos[2]] = align!(tiles, tiles[left_tile], tiles[common_tile_id], :left)
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
            picture[row, 1] = align!(tiles, tiles[top_id], tiles[me_id], :top)
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
            picture[1, row] = align!(tiles, tiles[left_id], tiles[me_id], :left)
            # println("Found top edge tile (1, $(row)) => $me_id")
        end
    end
    image, picture, tiles
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

remove_border(A::AbstractMatrix) = A[2:end-1,2:end-1]

function make_bitmap(picture)
    M = remove_border.(final_matrix.(picture))
    return vcat([hcat(M[r, :]...) for r in 1:size(picture,1)]...)
end

function get_stencil()
    str =   """
                  # 
#    ##    ##    ###
 #  #  #  #  #  #   """
    parse_line(s) = [c == ' ' ? 0 : 1 for c in s]
    vcat(map(transpose, parse_line.(split(str, "\n")))...)
end

function is_monster(stencil, A, row, col)
    r, c = size(stencil)
    area = A[row:row+r-1, col:col+c-1]
    masked_area = stencil .& area
    return sum(masked_area) == sum(stencil)
end

function find_monsters(stencil, bitmap)
    br, bc = size(bitmap)
    sr, sc = size(stencil)
    locations = []
    for i in 1:br-sr+1
        for j in 1:bc-sc+1
            if is_monster(stencil, bitmap, i, j)
                @info "Found monster: bitmap=$(hash(bitmap)) i=$i j=$j"
                push!(locations, (i,j))
            end
        end
    end
    return locations
end

function mark_monsters!(stencil, bitmap, locations)
    for loc in locations
        # @info "marking $loc"
        for row in 1:size(stencil, 1)
            for col in 1:size(stencil, 2)
                if stencil[row, col] == 1
                    # @info "marking $loc: $row $col"
                    bitmap[loc[1] + row - 1, loc[2] + col - 1] = 2
                end
            end
        end
    end
end

function part1()
    tiles = read_data("day20.txt")
    result = match_all(tiles)
    return prod([k for (k,v) in result if length(v) == 2])
end

function orient_and_find_monsters(stencil, bitmap)
    for bm in (bitmap, flip_matrix(bitmap, :horizontal), flip_matrix(bitmap, :vertical))
        for rotation in 0:3
            bm2 = rotate_matrix(bm, rotation)
            locations = find_monsters(stencil, bm2)
            if length(locations) > 0
                @info "Found monster in bitmap=$(hash(bm2))"
                return bm2, locations
            end
        end
    end
    error("can't find any monsters :-(")
end

# NOTE: Not finished yet... will come back to this later.
function part2()
    tiles = read_data("day20.txt")
    mappings = match_all(tiles)
    @info "mappings" mappings
    puzzle_ids, puzzle_picture, tiles = assemble(tiles, mappings)
    
    bitmap = make_bitmap(puzzle_picture)
    stencil = get_stencil()

    bitmap, locations = orient_and_find_monsters(stencil, bitmap)

    mark_monsters!(stencil, bitmap, locations)
    return count(==(1), bitmap)

    # return bitmap, cnt, sum(stencil)
    # return sum(bitmap) - cnt * sum(stencil)
end

function Base.show(io::IO, t::Tile)
    print(io, "$(t.id),$(t.orientation),$(t.rotation)")
end