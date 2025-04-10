using CSV, DataFrames, Statistics, Plots, PlotlyJS

df = CSV.read("data.csv",DataFrame)
first(df, 5)

describe(df)
# Most of the features seems to have missing values

unique(df.country)
#Going to test for a specific country like US and then go in depth on my interest

us_data = filter(row -> row.country == "United States", df)

mean_emissions = mean(skipmissing(us_data.co2))
median_emissions = median(skipmissing(us_data.co2))
std_emissions = std(skipmissing(us_data.co2))

println("Mean: $mean_emissions, Median: $median_emissions, Std Dev: $std_emissions")

Plots.plot(us_data.year, us_data.co2, title="US CO₂ Emissions Over Time",
     xlabel="Year", ylabel="CO₂ Emissions (million tonnes)", lw=2)

# Now, I will be investigating on several countries that are currently in conflicts(dated 7/4/25)
conflict_countries = [
    "Ukraine","Russia","Isreal","Palestine","Sudan","Syria","Yemen","Armenia","Azerbaijan",
    "Rwanda","Democratic Republic of Congo"
]

filtered_df = filter(row -> row.country in conflict_countries && !ismissing(row.co2),df)

# Plot CO₂ trends over time for each country
grouped = groupby(filtered_df, :country)

for g in grouped
    country = unique(g.country)[1]
    Plots.plot(g.year, g.co2, label=country, lw=2, xlabel="Year", ylabel="CO₂ Emissions", title="CO₂ Emissions for $country")
    display(current())  # Show each plot individually
end

#Selecting the year for the conflict in the respective countries
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

function percent_change_conflict(df::DataFrame,conflict_year::Int64)
    pre = filter(r -> r.year == conflict_year - 1, df)
    post = filter(r -> r.year == conflict_year + 1, df)

    if nrow(pre) == 0 || nrow(post) == 0 || any(ismissing.([pre.co2[1],post.co2[1]]))
        return missing
    end

    change = (post.co2[1] - pre.co2[1])/pre.co2[1] * 100
    return round(change,digits=2)
end

for country in keys(conflict_year)
    sub = filter(row -> row.country == country && !ismissing(row.co2),df)
    change = percent_change_conflict(sub, conflict_year[country])
    println("$country: $change % change after conflict ensued")
end

# Apart from Sudan, Israel and Palestine which are missing data for the period, 
# Ukraine, Rwanda, Syria, Yemen and Democratic Republic of Congo display decrease in Co2 emission in the conflict while
# Russia, Azerbaijan and Armenia shows increase in Co2 emission albeit slightly. 

# Let's explore if in some case if they have achieved recovery level after the conflict
function recovery_year(df::DataFrame,conflict_year::Int64)
    pre = filter(r -> r.year == conflict_year - 1, df)
    pre_emissions = nrow(pre) > 0 ? pre.co2[1] : missing
    if ismissing(pre_emissions)
        return missing
    end

    post = filter(r -> r.year > conflict_year && !ismissing(r.co2), df)
    for r in eachrow(post)
        if r.co2 >= pre_emissions
            return r.year
        end
    end
    return "Not recovered"
end

for country in keys(conflict_year)
    sub = filter(row -> row.country == country && !ismissing(row.co2),df)
    year = recovery_year(sub,conflict_year[country])
    println("$country: recovered in $year")
end

for (country, conflict_year) in conflict_year
    sub = filter(row -> row.country == country && !ismissing(row.co2), df)
    
    if nrow(sub) == 0
        continue
    end

    Plots.plot(sub.year, sub.co2, label="CO₂ Emissions", lw=2, 
         title="CO₂ Trend: $country", xlabel="Year", ylabel="Mt CO₂")
    vline!([conflict_year], label="Conflict Start", lw=2, lc=:red, ls=:dash)
    display(current())  # Display each plot individually
end

results = DataFrame(
    country = String[],
    conflict_year = Int[],
    percent_change = Union{Missing,Float64}[],
    recovery_year = Union{Missing,Int,String}[]
)

for country in keys(conflict_year)
    sub = filter(row -> row.country == country && !ismissing(row.co2), df)
    cyear = conflict_year[country]
    change = percent_change_conflict(sub, cyear)
    recov = recovery_year(sub, cyear)

    push!(results, (country, cyear, change, recov))
end

println(results)

#Creating interactive map for exploration
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

results[!,:code] = [country_codes[c] for c in results.country]

fig = PlotlyJS.Plot(  
    choropleth(
        locations=results.code,
        z=results.percent_change,
        text=["$(c): $(pc)% (Recovery: $(r))" for (c, pc, r) in zip(results.country, results.percent_change, results.recovery_year)],
        colorscale="RdBu",
        colorbar=attr(title="Emission Change (%)"),
        marker=attr(line=attr(color="darkgray", width=0.5))
    ),
    Layout(
        title="CO₂ Emission Change After Conflicts",
        geo=attr(
            showframe=false,
            showcoastlines=true,
            projection=attr(type="natural earth")
        )
    )
)

display(fig)