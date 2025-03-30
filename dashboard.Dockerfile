FROM node:lts-alpine AS build

# Install packages
USER root
RUN apk add --no-cache git

# Create the directory!
RUN mkdir -p /tmp && chown -R node:node /tmp
WORKDIR /tmp
USER node

# Bust cache (this will allow it to pull the latest version of the dashboard from the repo)
ARG CACHEBUST=1
ARG GIT_URL=https://github.com/Chaoskjell44/dashboard
ARG GIT_BRANCH=master
ARG COMMIT_HASH=532427b74b93fbb56b86c86dec036666f8eaba09

# Clone the repository to /tmp
RUN git clone -b $GIT_BRANCH $GIT_URL.git /tmp

# Switch to "known-working" commit.
RUN git reset --hard $COMMIT_HASH

# Switch directories to the frontend
WORKDIR /tmp/frontend

# Install node_modules (including development/build)
RUN npm install

# Build the frontend (and include the env variables required during buildtime)
ARG CLIENT_ID
ARG REDIRECT_URI
ARG API_URL
ARG WS_URL
ARG INVITE_URL

RUN npm run build

# Remove development node_modules
RUN npm prune --production


# Production container
FROM node:lts-alpine AS prod

RUN mkdir -p /app && chown -R node:node /app
WORKDIR /app
USER node

COPY --from=build --chown=node:node /tmp/frontend/package*.json /app/
COPY --from=build --chown=node:node /tmp/frontend/node_modules /app/node_modules
COPY --from=build --chown=node:node /tmp/frontend/public /app/public

ENV NODE_ENV=production
CMD ["npm", "run", "start"]