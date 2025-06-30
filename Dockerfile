# -------- Stage 1: Build the Flutter web app --------
FROM debian:bullseye AS build-env

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter
ENV FLUTTER_HOME=/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
RUN flutter channel stable
RUN flutter upgrade
RUN flutter doctor
RUN flutter config --enable-web  # ✅ Enable web support

# Set working directory and copy project
WORKDIR /app
COPY . .

# Get packages and build
RUN flutter pub get
RUN flutter build web --release

# -------- Stage 2: Serve with NGINX --------
FROM nginx:alpine

# Remove default NGINX content
RUN rm -rf /usr/share/nginx/html/*

# Copy built web files
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80 for Azure
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
