# Base image with Julia
FROM julia:1.10

# Set working directory
WORKDIR /model

# Copy environment files first (for better caching)
COPY Project.toml Manifest.toml ./

# Instantiate packages
RUN julia -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

# Copy the rest of the app
COPY model/ ./
COPY data/ ./data

# Expose port
EXPOSE 8050

# Run the Dash app
CMD ["julia", "Dashapp.jl"]
