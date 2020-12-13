filename() = "day12.txt"

function parse_line(line)
    instr = line[1]
    val = parse(Int, line[2:end])
    return (; instr, val)
end

read_data() = parse_line.(readlines(filename()))

function part1()
    pos = (x = 0, y = 0)
    rad = 0
    for d in read_data()
        if d.instr == 'N'
            pos = (x = pos.x, y = pos.y - d.val)
        elseif d.instr == 'S'
            pos = (x = pos.x, y = pos.y + d.val)
        elseif d.instr == 'E'
            pos = (x = pos.x + d.val, y = pos.y)
        elseif d.instr == 'W'
            pos = (x = pos.x - d.val, y = pos.y)
        elseif d.instr == 'F'
            pos = (x = pos.x + cos(rad) * d.val, y = pos.y + sin(rad) * d.val)
        elseif d.instr == 'L'
            rad -= deg2rad(d.val)
        elseif d.instr == 'R'
            rad += deg2rad(d.val)
        end
        @info "pos=$pos rad=$rad"
    end
    return abs(pos.x) + abs(pos.y)
end

function part2()
    pos = (x = 0, y = 0)
    way = (x = 10, y = -1)
    for d in read_data()
        dx, dy = way.x - pos.x, way.y - pos.y
        if d.instr == 'N'
            way = (x = way.x, y = way.y - d.val)
        elseif d.instr == 'S'
            way = (x = way.x, y = way.y + d.val)
        elseif d.instr == 'E'
            way = (x = way.x + d.val, y = way.y)
        elseif d.instr == 'W'
            way = (x = way.x - d.val, y = way.y)
        elseif d.instr == 'F'
            pos = (x = pos.x + d.val * dx, y = pos.y + d.val * dy)
            way = (x = way.x + d.val * dx, y = way.y + d.val * dy)
        elseif d.instr == 'L'
            r = sqrt(dx^2 + dy^2)
            θ = atan(dy, dx)
            ϕ = θ - deg2rad(d.val)
            way = (x = pos.x + r * cos(ϕ), y = pos.y + r * sin(ϕ))
        elseif d.instr == 'R'
            r = sqrt(dx^2 + dy^2)
            θ = atan(dy, dx)
            ϕ = θ + deg2rad(d.val)
            way = (x = pos.x + r * cos(ϕ), y = pos.y + r * sin(ϕ))
        else 
            error("wat")
        end
    end
    return abs(pos.x) + abs(pos.y)
end

# Animation

using Plots
using FileIO

function part2_animated()
    pos = (x = 0, y = 0)
    way = (x = 10, y = 1)
    anim = Animation()
    # img = FileIO.load("/Users/tomkwong/Downloads/iu.jpeg")
    # plot(img)
    # frame(anim)
    @animate for (i,d) in enumerate(read_data())
        dx, dy = way.x - pos.x, way.y - pos.y
        if d.instr == 'N'
            way = (x = way.x, y = way.y + d.val)
        elseif d.instr == 'S'
            way = (x = way.x, y = way.y - d.val)
        elseif d.instr == 'E'
            way = (x = way.x + d.val, y = way.y)
        elseif d.instr == 'W'
            way = (x = way.x - d.val, y = way.y)
        elseif d.instr == 'F'
            pos = (x = pos.x + d.val * dx, y = pos.y + d.val * dy)
            way = (x = way.x + d.val * dx, y = way.y + d.val * dy)
        elseif d.instr == 'L'
            r = sqrt(dx^2 + dy^2)
            θ = atan(dy, dx)
            ϕ = θ + deg2rad(d.val)
            way = (x = pos.x + r * cos(ϕ), y = pos.y + r * sin(ϕ))
        elseif d.instr == 'R'
            r = sqrt(dx^2 + dy^2)
            θ = atan(dy, dx)
            ϕ = θ - deg2rad(d.val)
            way = (x = pos.x + r * cos(ϕ), y = pos.y + r * sin(ϕ))
        else 
            error("wat")
        end
        if i % 2 == 0
            s, adx, ady = 3, abs(dx), abs(dy)
            ms = 15
            xlims = (min(pos.x, way.x) - s * adx, max(pos.x, way.x) + s * adx)
            ylims = (min(pos.y, way.y) - s * ady, max(pos.y, way.y) + s * ady)
            scatter([pos.x], [pos.y], xlims = xlims, ylims = ylims, markersize = ms,
                legend = nothing, ticks = nothing, showaxis = false, 
                background = "black", markershape = :octagon,
                title = "AoC Day 12 - Iteration $i")
            scatter!([way.x], [way.y], 
                xlims = xlims, ylims = ylims, markersize = ms + 5,
                markershape = :star)
            frame(anim)
        end
    end
    gif(anim, "day12_anim.gif", fps = 15)
end
