using CSV, DataFrames, Statistics, Plots

df = CSV.read("data.csv",DataFrame)
first(df, 5)

describe(df)
# Most of the features seems to have missing values

unique(df.country)
#Going to test for a specific country like US and then go in depth on my interest

