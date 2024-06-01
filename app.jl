module App
# set up Genie development environment
using GenieFramework
@genietools

using CSV, DataFrames, LinearAlgebra, ADNLPModels, JSOSolvers

# add your data analysis code
data = CSV.read(joinpath(@__DIR__, "data", "thurber.csv"), DataFrame)

# add reactive code to make the UI interactive
@app begin
    # reactive variables are tagged with @in and @out
    @out data_x = data.x
    @out data_y = data.y
    @in trigger_fit = false
    @out fit_x = Float64[]
    @out fit_y = Float64[]
    @in top_degree = 1
    @in bottom_degree = 1
    @out solver_output = "..."
    # @in λ = 1.0

    # watch a variable and execute a block of code when
    # its value changes
    @onbutton trigger_fit begin
        n = size(data, 1)
        model(β, x) = (β[1] + sum(β[i+1] * x^i for i = 1:top_degree)) / (1.0 + sum(β[i+1+top_degree] * x^i for i = 1:bottom_degree))

        F(β) = [
            model(β, data.x[i]) - data.y[i] for i = 1:n
        ]
        nls = ADNLSModel(
            F,
            randn(top_degree + bottom_degree + 1),
            n,
        )

        output = JSOSolvers.trunk(nls, max_iter=1000, max_time=3.0)

        β = output.solution

        fit_x = range(extrema(data.x)..., length=100)
        fit_y = [model(β, xi) for xi in fit_x]

        io = IOBuffer()
        println(io, output)
        solver_output = take!(io) |> String |> x -> split(x, "\n") |> x -> join(x, "<br>")
    end

    # @onchange λ begin
    #     # the values of result and msg in the UI will
    #     # be automatically updated
    #     n = size(data, 1)
    #     X = [ones(n) data.x]
    #     β = (X' * X + λ * I) \ (X' * data.y)

    #     fit_x = range(extrema(data.x)..., length=100)
    #     fit_y = β[1] .+ β[2] * fit_x
    # end
end

# register a new route and the page that will be
# loaded on access
@page("/", "app.jl.html")
end
