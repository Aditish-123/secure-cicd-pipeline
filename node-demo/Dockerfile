FROM node:22-trixie-slim
WORKDIR /app
RUN npm install -g npm@latest && \
    cd "$(npm root -g)/npm" && \
    npm install brace-expansion@2.1.7
COPY app.js .
EXPOSE 3000
CMD ["node", "app.js"]
