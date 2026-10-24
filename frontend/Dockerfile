FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom config and the static HTML
COPY nginx.conf /etc/nginx/conf.d/
COPY index.html /usr/share/nginx/html/

EXPOSE 80