FROM node:22-trixie-slim

WORKDIR /app

RUN npm install -g npm@latest

COPY app.js .

EXPOSE 3000

CMD ["node", "app.js"]
