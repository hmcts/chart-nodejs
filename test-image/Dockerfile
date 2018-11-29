FROM node:8-slim
ENV NODE_PORT 3000
COPY package* ./
RUN npm install
COPY . .
CMD ["npm", "start"]
