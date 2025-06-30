# -------- Stage 1: Build the Flutter web app --------
FROM debian:bullseye AS build-env

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl wget unzip xz-utils zip libglu1-mesa bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter (using tarball for reliability)
ENV FLUTTER_HOME=/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz -O /tmp/flutter.tar.xz \
    && mkdir /flutter \
    && tar xf /tmp/flutter.tar.xz -C /flutter --strip-components=1 \
    && rm /tmp/flutter.tar.xz

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

# Copy custom nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for Azure
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"] 
