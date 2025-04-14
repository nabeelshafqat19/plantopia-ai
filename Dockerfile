# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils libglu1-mesa cmake clang ninja-build pkg-config ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -ms /bin/bash developer
USER developer
WORKDIR /home/developer

# Install Flutter with a specific version
RUN git clone -b stable https://github.com/flutter/flutter.git
ENV PATH="/home/developer/flutter/bin:${PATH}"

# Configure Git and Flutter
RUN git config --global --add safe.directory /home/developer/flutter && \
    flutter precache && \
    flutter doctor --android-licenses || true && \
    flutter config --no-analytics && \
    flutter doctor

# Switch back to root for copying app files
USER root
WORKDIR /app

# Copy the app files to the container and ensure ownership
COPY --chown=developer:developer . .

# Switch back to non-root user to run Flutter commands
USER developer

# Get app dependencies and build for web
RUN flutter pub get && \
    flutter build web --release

# Stage 2: Create the production environment
FROM nginx:alpine

# Copy the built web files to nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy a custom nginx configuration (optional)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
