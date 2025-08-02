# 🧭 Summer of Making
This repository hosts the Ruby on Rails app for Hack Club's Summer of Making, a challenge for every teenager to build awesome projects and get rewarded! You can find more details on [summer.hackclub.com](https://summer.hackclub.com).

## Getting Started

1. Copy `.env.example` to `.env` (`cp .env.example .env`), and set the following variables:
   - `AIRTABLE_[...]` - optional. If not set, Airtable sync will be skipped.
   - `APP_HOST` - set to the domain you'll be hosting the app on, prefixed with the protocol - for example, `https://summer.hackclub.com`.
   - `BLAZER_DATABASE_URL` - optional. You can set this if you want to explore your database with [Blazer](https://github.com/ankane/blazer).
   - `DATABASE_URL` - set this to your PostgreSQL database connection string. An example is given below!
   - `SLACK_[...]` - `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`, and `SLACK_BOT_TOKEN` are required for logging in. Other variables are optional.
   - `UPDATES_STATUS` - set to `unlocked` to enable posting devlogs, `locked` otherwise.
   - `VOTING_STATUS` - same as `UPDATES_STATUS`, but for voting.
2. Create a Slack app [here](https://api.slack.com/apps/).
   - Click "Create New App", then "From a manifest".
   - Select the target workspace - most probably "Hack Club" - and click Next.
   - Select YAML, and paste in the contents of `slack_manifest.yaml`. You can find it in the root of the repo. You should also add `http://127.0.0.1:3000/auth/slack/callback` in `redirect_urls` if you're running this from GitHub Codespaces. 
   - Click "Install App" on the sidebar, then "Install to Hack Club". Copy the `User OAuth Token` and `Bot User OAuth Token`.
   - For the bot, make sure you have the following scopes enabled: `channels:history`, `chat:write`, `groups:history`, `im:write`, `reactions:write`, `users.profile:read`, `users:read`, `users:read.email`, `im:history`, `im:read`.
3. Make sure you have PostgreSQL running locally. You can use Docker to make this easier:

   ```bash
   docker run --name some-postgres -e POSTGRES_PASSWORD=pass -p 5432:5432 -d postgres
   ```

   You only need to do this once. Afterwards, to start it again, do:

   ```bash
   docker start some-postgres
   ```

   Then, if you aren't using `.env.example`, edit this line in your `.env` file:

   ```env
   DATABASE_URL=postgres://postgres:pass@localhost:5432/postgres
   ```
4. Make sure you have Ruby on Rails installed. If this proves to be difficult - or you're on Windows - we recommend using GitHub Codespaces with your local VSCode install.
5. Run `bundle install`. This might take a while - feel free to make yourself a cup of coffee and relax... ☕
6. Run `bin/rails db:prepare` to prepare/seed the database.
7. If you *do* have access to Identity Vault (IDV), set `BYPASS_IDV` and `MOCK_VERIFIED_USER` to `false` or remove them altogether in your `.env` file. They are set to `true` by default in `.env.example`.
8. Make sure you have VIPS (`libvips`) installed. For example, if you're running Ubuntu, do `sudo apt install libvips`.
9. Run `bin/dev` to start the development server on port 3000, then visit `http://localhost:3000` in your browser.
10. Profit?
