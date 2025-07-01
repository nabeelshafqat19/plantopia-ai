# -------- Stage 1: Build the Flutter web app --------
FROM debian:bullseye AS build-env

# Install required system packages
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
RUN flutter config --enable-web
RUN flutter precache --web
RUN flutter doctor -v

# Copy your app into the container
WORKDIR /app
COPY . .

# Clean and install dependencies
RUN flutter clean
RUN flutter pub get

# Attempt build with verbose logging
RUN echo "Starting Flutter web build..." && \
    flutter build web --release --verbose || \
    (echo "❌ Flutter build failed. Dumping log and exiting." && exit 1)

# -------- Stage 2: Serve with NGINX --------
FROM nginx:alpine

# Clear nginx default site
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
