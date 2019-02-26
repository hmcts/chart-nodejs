FROM node:10-slim
COPY package.json yarn.lock /
ADD ./config "/config"
RUN yarn install
COPY index.js /
ENV NODE_CONFIG_DIR="/config"
CMD ["yarn", "start"]
