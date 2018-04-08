
@testset "parsing simple matlab file" begin
    data = parse_matlab_file("../test/data/matlab_01.m")

    @test length(data) == 6
    @test length(data["mpc.bus"]) == 2
    @test length(data["mpc.gen"]) == 1
    @test length(data["mpc.branch"]) == 1

    @test isa(data["mpc.version"], SubString{String})
    @test isa(data["mpc.baseMVA"], Float64)

    @test data["mpc.gen"][1][2] == 1098.17
end

@testset "parsing complex matlab file" begin
    data = parse_matlab_file("../test/data/matlab_02.m")

    @test length(data) == 16
    @test length(data["mpc.bus"]) == 3
    @test length(data["mpc.gen"]) == 3
    @test length(data["mpc.branch"]) == 3
    @test length(data["mpc.branch_limit"]) == 3

    @test length(data["mpc.areas"][1]) == 2
    @test length(data["mpc.branch_limit"][1]) == 2

    @test isa(data["mpc.version"], SubString{String})
    @test isa(data["mpc.baseMVA"], Float64)
    @test isa(data["mpc.const_str"], SubString{String})

    @test data["mpc.areas_cells"][1][1] == "Area 1"
    @test data["mpc.areas_cells"][1][3] == 987
end

@testset "parsing matlab extended features" begin
    data, func, columns = parse_matlab_file("../test/data/matlab_02.m", extended=true)

    @test func == "matlab_02"

    @test length(columns) == 4

    @test columns["mpc.areas_named"][2] == "refbus"

    for (k,v) in columns
        @test haskey(data, k)
        @test length(data[k][1]) == length(v)
    end
end


@testset "summary feature matlab data" begin
    data = parse_matlab_file("../test/data/matlab_01.m")

    output = sprint(InfrastructureModels.summary, data)

    line_count = count(c -> c == '\n', output)
    @test line_count >= 5 && line_count <= 10 
    @test contains(output, "mpc.baseMVA")
    @test contains(output, "mpc.version")
    @test contains(output, "mpc.bus_name: [(2)]")
end

@testset "summary feature component data" begin
    output = sprint(InfrastructureModels.summary, generic_network_data)

    line_count = count(c -> c == '\n', output)
    @test line_count >= 18 && line_count <= 22
    @test contains(output, "dict: {(4)}")
    @test contains(output, "list: [(4)]")
    @test contains(output, "default values:")
    @test contains(output, "Table Counts")
    @test contains(output, "Table: comp")
end


@testset "network replicate data" begin
    mn_data = InfrastructureModels.replicate(generic_network_data, 3)

    @test length(mn_data) == 6
    @test mn_data["multinetwork"]
    @test haskey(mn_data, "per_unit")
    @test haskey(mn_data, "a")
    @test haskey(mn_data, "b")
    @test haskey(mn_data, "list")

    @test length(mn_data["nw"]) == 3
    @test mn_data["nw"]["1"] == mn_data["nw"]["2"]
    @test mn_data["nw"]["2"] == mn_data["nw"]["3"]
end


@testset "update_data! feature" begin
    data = JSON.parse("{
        \"per_unit\":false,
        \"a\":1,
        \"b\":\"bloop\",
        \"c\":{
            \"1\":{
                \"a\":2,
                \"b\":3
            },
            \"3\":{
                \"a\":2,
                \"b\":3
            }
        }
    }")

    mod = JSON.parse("{
        \"per_unit\":false,
        \"e\":1.23,
        \"b\":[4,5,6],
        \"c\":{
            \"1\":{
                \"a\":4,
                \"b\":\"bloop\"
            },
            \"2\":{
                \"a\":4,
                \"b\":false
            }
        }
    }")

    update_data!(data, mod)

    @test length(data) == 5
    @test data["a"] == 1
    @test data["b"][2] == 5
    @test length(data["c"]) == 3
    @test data["e"] == 1.23

    @test data["c"]["1"]["a"] == 4
    @test data["c"]["1"]["b"] == "bloop"

    @test data["c"]["2"]["a"] == 4
    @test data["c"]["2"]["b"] == false

    @test data["c"]["3"]["a"] == 2
    @test data["c"]["3"]["b"] == 3
end

