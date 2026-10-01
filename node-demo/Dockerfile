FROM node:22-trixie-slim

WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g npm@latest

COPY app.js .

EXPOSE 3000

CMD ["node", "app.js"]
