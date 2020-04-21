FROM hmctspublic.azurecr.io/base/node:12-alpine as base
USER hmcts
COPY package.json yarn.lock ./
ADD ./config "/config"
RUN yarn install --production && yarn cache clean
COPY index.js ./
ENV NODE_CONFIG_DIR="/config"
CMD ["yarn", "start"]
