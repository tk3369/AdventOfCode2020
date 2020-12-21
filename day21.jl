filename() = "day21.txt"

struct Food{T,S}
    ingredients::Set{T}
    allergens::Set{S}
end

function read_data()
    function parse_line(s)
        m = match(r"(.*) \(contains (.*)\)$", s)
        ingredients = split(m.captures[1], " ")
        allergens = split(m.captures[2], ", ")
        return Food(Set(ingredients), Set(allergens))
    end
    lines = readlines(filename())
    return parse_line.(lines)
end

function all_allergens(foods)
    return mapreduce(Base.Fix2(getproperty, :allergens),
        union, foods)
end

# Which ingredients might contain a specific allergen?
function candidate_ingredients(foods, allergen)
    related = [f for f in foods if allergen in f.allergens]
    return intersect([r.ingredients for r in related]...)
end

# Create a list of allergen => candidate ingredients
function create_work_list(foods)
    return Dict(a => candidate_ingredients(foods, a) 
        for a in all_allergens(foods))
end

# Resovle the work list.
# If an allergen is mapped to exactly one ingredient, then 
# it's resolved. Then, remove this ingredient from the work
# list. Repeat until all alergens are resolved.
function resolve(work_list)
    result = Dict()
    queue = collect(keys(work_list))
    while length(result) < length(work_list)
        allergen = popfirst!(queue)
        if length(work_list[allergen]) == 1
            ingredient = only(work_list[allergen])
            result[allergen] = ingredient
            for k in keys(work_list)  # remove from all others
                if k != allergen
                    delete!(work_list[k], ingredient)
                end
            end
        else
            push!(queue, allergen)
        end
    end
    return result
end

# Count how many ingredients are left after excluding the
# exclusion list.
function remaining_ingredients(foods, exclude_ingredients)
    cnt = 0
    for f in foods
        s = setdiff(f.ingredients, exclude_ingredients)
        cnt += length(s)
    end
    return cnt
end

function resolve_allergens(foods)
    work_list = create_work_list(foods)
    return resolve(work_list)
end

function part1()
    foods = read_data()
    mapped = resolve_allergens(foods)
    return remaining_ingredients(foods, collect(values(mapped)))
end

function part2()
    foods = read_data()
    mapped = resolve_allergens(foods)
    return join([mapped[k] for k in sort(collect(keys(mapped)))], ",")
end
