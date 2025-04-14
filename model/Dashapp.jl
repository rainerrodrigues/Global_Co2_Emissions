using Dash, DashCoreComponents, DashHtmlComponents, PlotlyJS, CSV, DataFrames, Statistics

# Load Data
df = CSV.read("data.csv", DataFrame)

conflict_year = Dict(
    "Ukraine" => 2014,
    "Russia" => 2022,
    "Israel" => 2023,
    "Palestine" => 2023,
    "Sudan" => 2023,
    "Yemen" => 2015,
    "Syria" => 2011,
    "Armenia" => 2020,
    "Azerbaijan" => 2020,
    "Rwanda" => 1994,
    "Democratic Republic of Congo" => 1997
)

country_codes = Dict(
    "Ukraine" => "UKR",
    "Russia" => "RUS",
    "Israel" => "ISR",
    "Palestine" => "PSE",
    "Sudan" => "SDN",
    "Yemen" => "YEM",
    "Syria" => "SYR",
    "Armenia" => "ARM",
    "Azerbaijan" => "AZE",
    "Rwanda" => "RWA",
    "Democratic Republic of Congo" => "COD"
)

function percent_change_conflict(df::DataFrame, conflict_year::Int64)
    pre = filter(r -> r.year == conflict_year - 1, df)
    post = filter(r -> r.year == conflict_year + 1, df)
    if nrow(pre) == 0 || nrow(post) == 0 || any(ismissing.([pre.co2[1], post.co2[1]]))
        return missing
    end
    return round((post.co2[1] - pre.co2[1]) / pre.co2[1] * 100, digits=2)
end

function recovery_year(df::DataFrame, conflict_year::Int64)
    pre = filter(r -> r.year == conflict_year - 1, df)
    if nrow(pre) == 0 || ismissing(pre.co2[1])
        return missing
    end
    pre_emissions = pre.co2[1]
    post = filter(r -> r.year > conflict_year && !ismissing(r.co2), df)
    for r in eachrow(post)
        if r.co2 >= pre_emissions
            return r.year
        end
    end
    return "Not recovered"
end

function year_to_bubblesize(recovery)
    if recovery isa Int
        return clamp(2025 - recovery, 5, 40)
    else
        return 10
    end
end

function prepare_results(df)
    results = DataFrame(country = String[], conflict_year = Int[],
                        percent_change = Union{Missing, Float64}[],
                        recovery_year = Union{Missing, Int, String}[],
                        code = String[], bubble_size = Float64[])

    for (country, cyear) in conflict_year
        sub = filter(row -> row.country == country && !ismissing(row.co2), df)
        change = percent_change_conflict(sub, cyear)
        recov = recovery_year(sub, cyear)
        code = country_codes[country]
        size = year_to_bubblesize(recov)
        push!(results, (country, cyear, change, recov, code, size))
    end
    return results
end

results = prepare_results(df)

function generate_map(map_type::String)
    trace = if map_type == "scattergeo"
        scattergeo(
            locationmode="ISO-3",
            locations=results.code,
            text=["$(c)<br>ΔCO₂: $(pc)%<br>Recovery: $(r)" for (c, pc, r) in zip(results.country, results.percent_change, results.recovery_year)],
            mode="markers",
            marker=attr(
                size=results.bubble_size,
                color=results.percent_change,
                colorscale="RdBu",
                colorbar=attr(title="CO₂ Δ%"),
                line=attr(width=0.5, color="white")
            )
        )
    else
        choropleth(
            locationmode="ISO-3",
            locations=results.code,
            z=results.percent_change,
            text=["$(c)<br>ΔCO₂: $(pc)%<br>Recovery: $(r)" for (c, pc, r) in zip(results.country, results.percent_change, results.recovery_year)],
            colorscale="RdBu",
            colorbar=attr(title="CO₂ Δ%"),
            marker=attr(line=attr(color="white", width=0.5))
        )
    end

    layout = Layout(
        title="Conflict-Driven CO₂ Emission Change and Recovery",
        geo=attr(
            bgcolor="black",
            showland=true,
            landcolor="rgb(50, 50, 50)",
            subunitwidth=1,
            countrywidth=1,
            subunitcolor="white",
            countrycolor="white"
        )
    )
    return Plot(trace, layout)
end

app = dash()

app.layout = html_div([
    html_h1("Conflict & CO₂ Emissions Dashboard"),
    dcc_dropdown(
        id="map-type",
        options=[
            ("Choropleth", "choropleth"),
            ("Scattergeo Bubble", "scattergeo")
        ],
        value="scattergeo"
    ),
    dcc_graph(id="map-graph")
])

callback!(app, Output("map-graph", "figure"), Input("map-type", "value")) do map_type
    return generate_map(map_type)
end

run_server(app, "0.0.0.0", debug=true)
