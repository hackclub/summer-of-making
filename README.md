# Summer of making

A 3 week journey into making!

## Getting Started

1. Copy over the `.env.example` file to `.env` by running `cp .env.example .env`
2. For the Slack bot, make sure you have the following scopes enabled: \
   `channels:history`, `chat:write`, `groups:history`, `im:write`, `reactions:write`, `users.profile:read`, `users:read`, `users:read.email`, `im:history`, `im:read`.
3. Make sure you have PostgreSQL running locally. You can use Docker to make this easier:

   ```bash
   docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres
   ```

   Then edit this line in your `.env` file:

   ```env
   DATABASE_URL=postgres://postgres:mysecretpassword@localhost:5432/postgres
   ```

4. Run `bin/rails db:prepare` to prepare/seed the database.
5. Comment out any airtable refrence from [`app/models/user.rb`](/app/models/user.rb), unless you have access to the journey airtable. (if you do comment it out, make sure you dont commit it) If you do have access, you can run `bin/rails airtable:sync` to sync the data from Airtable to your local database.
6. Run `bin/dev` to start the development server on port 3000, then visit `http://localhost:3000` in your browser.
7. Profit???

> [!WARNING]
> Using Codespaces? Make sure that `libvips` is installed to ensure everything works properly:
>
> ```bash
> sudo apt update
> sudo apt install libvips42
> ```
