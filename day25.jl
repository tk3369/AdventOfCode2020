function transform(subject_number, magic, loop_size)
    v = 1
    for i in 1:loop_size
        v *= subject_number
        v %= magic
    end
    return v
end

function find_loop_size(subject_number, magic, target)
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
    magic = 20201227
    card_loop_size = find_loop_size(7, magic, 12092626)
    door_loop_size = find_loop_size(7, magic, 4707356)
    transform(12092626, magic, door_loop_size)
end

# No part2 :-) I had to finish Day 20 to get the final golden star!

# ---- Iteration ----

struct CryptoTransform{T <: Integer}
    subject::T
    magic::T
end

function Base.iterate(ct::CryptoTransform, state = nothing)
    if state === nothing
        return 1, 1
    else
        state = state * ct.subject % magic
        return state, state
    end
end

Base.IteratorSize(::Type{CryptoTransform}) = Base.IsInfinite()

transform_iter(ct::CryptoTransform, loop_size::Int) =
    first(x for (i,x) in enumerate(ct) if i == loop_size)

find_loop_size_iter(ct::CryptoTransform, public_key::Int) =
    first(i for (i,x) in enumerate(ct) if x == public_key)

function part1_iter()
    magic = 20201227
    ct = CryptoTransform(7, magic)
    card_loop_size = find_loop_size_iter(ct, 12092626)
    door_loop_size = find_loop_size_iter(ct, 4707356)

    search = CryptoTransform(12092626, magic)
    transform_iter(search, door_loop_size)
end

# ---- Functional style ----

using Lazy

# reducer
calc(subject::Int, magic::Int) = (x, _) -> subject * x % magic

# apply reducer many times
trans(subject::Int, magic::Int, n::Int) = foldl(calc(subject, magic), 1:n; init = 1)

# recursive until target is hit
@rec function loopsize(subject::Int, magic::Int, target::Int, x::Int, n::Int)
    v = calc(subject, magic)(x, n)
    v == target ? n : loopsize(subject, magic, target, v, n + 1)
end

function part1_lazy()
    magic = 20201227
    card_loop_size = loopsize(7, magic, 12092626, 1, 1)
    door_loop_size = loopsize(7, magic, 4707356, 1, 1)
    trans(12092626, magic, door_loop_size)
end

# ---- Using channel (credit: Doug) ----

function transform_subject_number(subjnum = 7, buffer_size = 10000)
    x = 1
    Channel{Int}(buffer_size) do c
        while true
            x = (x * subjnum) % 20201227
            put!(c, x)
        end
    end
end

function loopsize_doug(key)
    return first(i for (i, v) = enumerate(transform_subject_number()) 
                        if v == key)
end

function transform_doug(key, loop_size)
    return first(v for (i, v) = enumerate(transform_subject_number(key)) 
                        if i == loop_size)
end

function part1_doug()
    card_loop_size = loopsize_doug(12092626)
    door_loop_size = loopsize_doug(4707356)
    transform_doug(12092626, door_loop_size)
end
