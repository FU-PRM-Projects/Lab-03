# Stage 1: Build the Rust binary
FROM rust:slim-bookworm AS builder

WORKDIR /app

# Copy manifest files first to cache dependencies
COPY Cargo.toml Cargo.lock ./

# Create a dummy main.rs to pre-build and cache dependencies
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy actual source code and build the application
COPY src ./src
RUN touch src/main.rs && cargo build --release

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/discord_bot /usr/local/bin/discord_bot

CMD ["discord_bot"]
