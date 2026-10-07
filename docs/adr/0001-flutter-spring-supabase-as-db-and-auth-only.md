# Flutter client, Spring backend, Supabase only as Postgres and auth

The client is Flutter (one codebase for web and mobile, and learning Flutter is an explicit goal of the project). All data access goes through our own Spring Boot backend, which also owns the domain logic (Funding Order, Covered, Next Milestone, Unassigned Earnings). Supabase is used only as a hosted Postgres (connected via JDBC) and as the identity provider: Flutter signs in with Supabase Auth and Spring validates the Supabase JWT as an OAuth2 resource server. The domain knows the user only as the `user_id` from the token.

## Considered Options

- **Flutter talking to Supabase directly (RLS), no backend** — less to build, but the coverage logic would live in Dart, and Supabase would become a hard dependency rather than a replaceable Postgres + token issuer.
- **Hybrid (computation in both Spring and Flutter)** — instant feedback, but the same domain logic written twice.
- **Custom auth in Spring** — weeks of work (passwords, email verification, reset, OAuth) that add nothing to the product.
- **React PWA** — fastest to ship given an existing prototype, rejected because the author is not fluent in React and wants to learn Flutter.

## Consequences

- Every Work Log write waits for a server round-trip before the new Next Milestone is shown; acceptable for one entry per day.
- Leaving Supabase means moving the Postgres database and swapping the JWT issuer; no domain code changes.
