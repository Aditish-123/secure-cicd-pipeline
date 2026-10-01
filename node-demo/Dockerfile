FROM node:22.23.3-trixie-slim
WORKDIR /app
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
COPY app.js .
EXPOSE 3000
CMD ["node", "app.js"]
