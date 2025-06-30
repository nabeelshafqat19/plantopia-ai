# Step 1: Build the Flutter web app
FROM dart:stable AS build

WORKDIR /app
COPY . .

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support (if not already enabled)
RUN flutter config --enable-web

# Get dependencies and build
RUN flutter pub get
RUN flutter build web

# Step 2: Serve with Nginx
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 
