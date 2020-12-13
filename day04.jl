
filename() = "day04.txt"

parse_data() = let data = String(read(filename()))
    strip.(split(data, "\n\n"))
end

parse_passport(passport) = Dict(f[1]=>f[2] for f in split.(split(passport, r"[ \n]"), ":"))

# Check and make sure that all required password fields are present
function part1()
    required_fields = ["byr","iyr","eyr","hgt","hcl","ecl","pid"]
    valid_passport(passport) = all(haskey(passport, k) for k in required_fields)
    passports = parse_passport.(parse_data())
    count(valid_passport.(passports))
end

# Check password rules for each field
function part2()
    match_pattern(s, pattern) = match(pattern, s) !== nothing
    chk_byr(s) = match_pattern(s, r"^[12][0-9][0-9][0-9]$") && 1920 <= parse(Int, s) <= 2002
    chk_iyr(s) = match_pattern(s, r"^[12][0-9][0-9][0-9]$") && 2010 <= parse(Int, s) <= 2020
    chk_eyr(s) = match_pattern(s, r"^[12][0-9][0-9][0-9]$") && 2020 <= parse(Int, s) <= 2030
    chk_hgt(s) = let m = match(r"^([1-9][0-9]*)(cm|in)$", s)
        if m === nothing
            false
        elseif m[2] == "cm" 
            150 <= parse(Int, m[1]) <= 193
        else # in
            59 <= parse(Int, m[1]) <= 76
        end
    end
    chk_hcl(s) = match_pattern(s, r"^#[0-9a-f]{6}$")
    chk_ecl(s) = s ∈ ["amb", "blu", "brn", "gry", "grn", "hzl", "oth"]
    chk_pid(s) = match_pattern(s, r"^[0-9]{9}$")

    checkers = [chk_byr, chk_iyr, chk_eyr, chk_hgt, chk_hcl, chk_ecl, chk_pid]
    fields   = ["byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid"]
    chk_all(passport) = all(haskey(passport, f) ? c(passport[f]) : false for (c,f) in zip(checkers, fields))

    passports = parse_passport.(parse_data())
    return count(chk_all.(passports))
end
