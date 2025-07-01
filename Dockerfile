# -------- Stage 1: Build the Flutter web app --------
FROM debian:bullseye AS build-env

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV FLUTTER_HOME=/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
WORKDIR $FLUTTER_HOME
RUN flutter channel stable && flutter upgrade

# Enable web support
RUN flutter config --enable-web

# Pre-cache Flutter tools (this prevents version issues)
RUN flutter precache --web

# Run doctor (debugging step - can be removed later)
RUN flutter doctor -v

# Set working directory for app code
WORKDIR /app

# Copy your app source code
COPY . .

# Get pub packages
RUN flutter pub get

# Build Flutter web app with verbose logging
RUN flutter build web --release --verbose # <--- Add --verbose here

# -------- Stage 2: Serve with NGINX --------
FROM nginx:alpine

# Clear default nginx web content
RUN rm -rf /usr/share/nginx/html/*

# Copy built web assets to nginx folder
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Optional: copy custom nginx config
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
