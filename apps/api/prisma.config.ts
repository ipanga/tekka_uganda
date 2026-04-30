// Prisma 7 requires the datasource URL to live in this config file, not
// in schema.prisma (https://pris.ly/d/config-datasource).
//
// `dotenv` is intentionally NOT imported here: the prod Docker image is
// built with `npm ci --omit=dev`, so dotenv wouldn't be available at
// runtime and the import would crash this config. DATABASE_URL is
// provided by docker-compose's `--env-file .env` when running
// `prisma migrate deploy`, and by `dotenv-cli` (`start:dev` /
// `start:debug` scripts in package.json) for local dev.
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    url: process.env["DATABASE_URL"],
  },
});
