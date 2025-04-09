# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip && \
    rm -rf /var/lib/apt/lists/*

# Increase Git buffer size to handle large repositories
RUN git config --global http.postBuffer 524288000

# Install Flutter
RUN git clone --depth 1 https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"

# Create a non-root user
RUN useradd -ms /bin/bash flutteruser

# Change ownership of the Flutter directory
RUN chown -R flutteruser:flutteruser /flutter

# Switch to the non-root user
USER flutteruser

# Run Flutter commands as non-root
RUN flutter doctor
RUN flutter channel stable || true  # Ignore errors if the channel is already stable

# Retry mechanism for flutter upgrade
RUN for i in 1 2 3; do flutter upgrade && break || sleep 10; done

# Verify Flutter version
RUN flutter --version

# Copy the app files to the container
WORKDIR /app
COPY . .

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
