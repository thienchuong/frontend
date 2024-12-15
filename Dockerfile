# syntax=docker/dockerfile:1

ARG NODE_VERSION=20.10.0

################################################
# Use node image for base image for all stages.
FROM node:${NODE_VERSION}-alpine as base

# Set working directory for all build stages.
WORKDIR /usr/src/app
#################################################
# Create a stage for installing production dependecies.
FROM base as deps

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage bind mounts to package.json and package-lock.json to avoid having to copy them
# into this layer.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

FROM base as final
# Use production node environment by default.
ENV NODE_ENV production
# Copy the production dependencies from the deps stage
COPY --from=deps /usr/src/app/node_modules ./node_modules
# give node user permission to write to the node_modules directory
RUN chmod -R 777 node_modules/
# Run the application as a non-root user.
USER node
# Copy the application code.
COPY . .
# Give instruction the port that the application listens on.
EXPOSE 3000

# Run the application.
CMD npm start
