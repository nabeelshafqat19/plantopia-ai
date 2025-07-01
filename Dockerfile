# -------- Stage 1: Build the Flutter web app --------
FROM debian:bullseye AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set environment
ENV FLUTTER_HOME=/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
WORKDIR $FLUTTER_HOME
RUN flutter channel stable && flutter upgrade
RUN flutter config --enable-web
RUN flutter precache --web
RUN flutter doctor -v

# Build app
WORKDIR /app
COPY . .

RUN flutter clean
RUN flutter pub get
RUN flutter build web --release --verbose

# -------- Stage 2: Serve with NGINX --------
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
