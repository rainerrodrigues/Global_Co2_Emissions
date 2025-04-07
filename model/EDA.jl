using CSV, DataFrames, Statistics, Plots

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

plot(us_data.year, us_data.co2, title="US CO₂ Emissions Over Time",
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
    plot(g.year, g.co2, label=country, lw=2, xlabel="Year", ylabel="CO₂ Emissions", title="CO₂ Emissions for $country")
    display(current())  # Show each plot individually
end