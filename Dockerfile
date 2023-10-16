FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
COPY . /app
WORKDIR /app

FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run -r build

FROM base AS common
COPY --from=prod-deps /app/packages/common/node_modules/ /app/packages/common/node_modules
COPY --from=build /app/packages/common/dist /app/packages/common/dist

FROM common AS app1
COPY --from=prod-deps /app/packages/app1/node_modules/ /app/packages/app1/node_modules
COPY --from=build /app/packages/app1/dist /app/packages/app1/dist
WORKDIR /app/packages/app1
EXPOSE 8000
CMD [ "pnpm", "start" ]

FROM common AS app2
COPY --from=prod-deps /app/packages/app2/node_modules/ /app/packages/app2/node_modules
COPY --from=build /app/packages/app2/dist /app/packages/app2/dist
WORKDIR /app/packages/app2
EXPOSE 8001
CMD [ "pnpm", "start" ]
