# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils libglu1-mesa cmake clang ninja-build pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -ms /bin/bash developer
USER developer
WORKDIR /home/developer

# Install Flutter with specific version
RUN git clone -b stable https://github.com/flutter/flutter.git
ENV PATH="/home/developer/flutter/bin:${PATH}"

# Initialize Flutter
RUN flutter precache
RUN flutter doctor --android-licenses || true
RUN flutter config --no-analytics
RUN flutter doctor

# Switch back to root for remaining operations
USER root
WORKDIR /app

# Copy the app files to the container
COPY --chown=developer:developer . .

# Get app dependencies and build for web
RUN flutter pub get
RUN flutter build web --release

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
