FROM node:22-trixie-slim
WORKDIR /app
COPY package.json .
RUN npm install --omit=dev
COPY app.js .
EXPOSE 3000
CMD ["node", "app.js"]
