# Build stage: Flutter web build
FROM debian:bullseye-slim AS build

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y git wget xz-utils

# Download and extract Flutter SDK
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.5-stable.tar.xz -O /tmp/flutter.tar.xz \
    && mkdir /flutter \
    && tar xf /tmp/flutter.tar.xz -C /flutter --strip-components=1 \
    && rm /tmp/flutter.tar.xz

ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

COPY . .

RUN flutter config --enable-web
RUN flutter pub get
RUN flutter build web

# Serve stage: Nginx
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 
