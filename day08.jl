read_data() = readlines("day08.txt")

# read_data() = split("""
# nop +0
# acc +1
# jmp +4
# acc +3
# jmp -3
# acc -99
# acc +1
# jmp -4
# acc +6""", "\n")

function parse_instructions()
    lines = read_data()
    instructions = split.(lines, " ")
    return map(x -> (Symbol(x[1]), parse(Int, x[2])), instructions)
end

function execute(instructions)
    val = 0
    len = length(instructions)
    visited = falses(len)
    i = 1
    @inbounds while true
        # needed by Part2
        i > len && return (val, :terminated)

        # Next instruction
        instr = instructions[i]
        visited[i] && return (val, :infinite)

        # Remember this instruction
        # push!(visited, i)
        visited[i] = true

        # Execute!
        if instr[1] === :acc 
            val += instr[2]
        elseif instr[1] === :jmp
            i += instr[2] - 1
        end
        i += 1
    end
end

part1() = execute(parse_instructions())

# part 2 brute force

function part2()
    prog = parse_instructions()
    sz = length(prog)
    jmps = findall(x -> x[1] == :jmp, prog)
    for j in jmps
        np = modified_program(prog, j, :nop)
        result = execute(np)
        result[2] == :terminated && return result[1]
    end
    # NOTE: 
    # I didn't have to complete the code by replacing nop with jmp because I have
    # already reached an answer. Otherwise, it would be simialr code as follows.
    # nops = [i for i in 1:sz if prog[i][1] == :nop && prog[i][2] != 0]
    return "not found"
end

function modified_program(prog, i, chg)
    prog = copy(prog)
    prog[i] = (chg, prog[i][2])
    return prog
end


