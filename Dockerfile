# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip && \
    rm -rf /var/lib/apt/lists/*

# Configure git for better reliability
RUN git config --global http.postBuffer 524288000 && \
    git config --global core.compression 0 && \
    git config --global http.lowSpeedLimit 1000 && \
    git config --global http.lowSpeedTime 300

# Install Flutter with retry logic and shallow clone
RUN for i in {1..3}; do \
        git clone --depth 1 --single-branch https://github.com/flutter/flutter.git /flutter && break || \
        rm -rf /flutter && sleep 5; \
    done

ENV PATH="/flutter/bin:${PATH}"

# Precache Flutter dependencies with retry logic
RUN for i in {1..3}; do \
        flutter precache && break || \
        sleep 5; \
    done

RUN flutter doctor
RUN flutter channel stable
RUN flutter upgrade

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
