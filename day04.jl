samples="""ecl:gry pid:860033327 eyr:2020 hcl:#fffffd
byr:1937 iyr:2017 cid:147 hgt:183cm

iyr:2013 ecl:amb cid:350 eyr:2023 pid:028048884
hcl:#cfa07d byr:1929

hcl:#ae17e1 iyr:2013
eyr:2024
ecl:brn pid:760753108 byr:1931
hgt:179cm

hcl:#cfa07d eyr:2025 pid:166559648
iyr:2011 ecl:brn hgt:59in
"""

parse_data(data) = strip.(split(data, "\n\n"))

parse_passport(passport) = Dict(f[1]=>f[2] for f in split.(split(passport, r"[ \n]"), ":"))

let required_fields = ["byr","iyr","eyr","hgt","hcl","ecl","pid"]
    valid_passport(passport) = all(haskey(passport, k) for k in required_fields)
end

# test sample
passports = parse_passport.(parse_data(sample))
count(valid_passport.(passports))

# part 1
passports = parse_passport.(parse_data(String(read("day04.txt"))))
count(valid_passport.(passports))

# part2
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

# test sample2
samples2_invalid = """eyr:1972 cid:100
hcl:#18171d ecl:amb hgt:170 pid:186cm iyr:2018 byr:1926

iyr:2019
hcl:#602927 eyr:1967 hgt:170cm
ecl:grn pid:012533040 byr:1946

hcl:dab227 iyr:2012
ecl:brn hgt:182cm pid:021572410 eyr:2020 byr:1992 cid:277

hgt:59cm ecl:zzz
eyr:2038 hcl:74454a iyr:2023
pid:3556412378 byr:2007"""
passports = parse_passport.(parse_data(samples2_invalid))
count(chk_all.(passports)) == 0

samples2_valid = """pid:087499704 hgt:74in ecl:grn iyr:2012 eyr:2030 byr:1980
hcl:#623a2f

eyr:2029 ecl:blu cid:129 byr:1989
iyr:2014 pid:896056539 hcl:#a97842 hgt:165cm

hcl:#888785
hgt:164cm byr:2001 iyr:2015 cid:88
pid:545766238 ecl:hzl
eyr:2022

iyr:2010 hgt:158cm hcl:#b6652a ecl:blu byr:1944 eyr:2021 pid:093154719"""

passports = parse_passport.(parse_data(samples2_valid))
count(chk_all.(passports)) == 4

# part 2
passports = parse_passport.(parse_data(String(read("day04.txt"))))
count(chk_all.(passports))  # ans=186
