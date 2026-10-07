# Always-on backend hosting instead of free sleeping tiers

The app is opened roughly once a day, so on a free tier that sleeps when idle (Render free, Cloud Run scaled to zero) nearly every visit would hit a 10–60 s Spring cold start, killing the end-of-day logging ritual. We therefore pay for a PaaS instance that does not sleep (Railway, Fly.io, or paid Render; chosen at deploy time). Supabase's free tier pauses after 7 days of inactivity, so the backend runs a scheduled lightweight query to keep it awake.
