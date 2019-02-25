FROM node:10-slim
COPY package.json .
COPY yarn.lock .
RUN yarn install
COPY index.js .
ADD ./config "/config"
ENV NODE_CONFIG_DIR="/config"
CMD ["yarn", "start"]
