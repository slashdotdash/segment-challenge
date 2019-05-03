# Segment Challenge

[Segment Challenge](https://segmentchallenge.com/) is an Elixir Phoenix web application built using [Commanded](https://github.com/commanded/commanded) for CQRS/ES. The front-end is mostly server generated HTML plus a few React components for responsive forms.

![Segment Challenge homepage](/assets/static/images/segment-challenge-homepage.png "Segment Challenge homepage")

### What is Segment Challenge?

Segment Challenge allows any Strava athlete to host their own Strava-based challenge. [Strava](http://strava.com/) is a social network for athletes.

A challenge comprises one or more stages. You can create a challenge based around different Strava segments, or an activity challenge where you decide what type of activity to record (distance, duration, or elevation) and can set an optional goal.

### Why is this being made public?

In March 2019 Strava decided to revoke access to the Strava API for Segment Challenge as _"... the purpose of this app is competitive with Strava"_. Without API access the site cannot function. I am making the source code public to demonstrate one approach to building event sourced Elixir applications using Commanded.

### Can I run this locally?

Yes, first you need to create a Strava account and create your own [Strava API Application](https://strava.com/settings/api) and then follow the steps below to clone the Git repo, prepare, and run the application.

### Can I deploy this publicly?

No, Strava will _not allow_ Segment Challenge access to their API in public.

---

### Prerequisites

Install Elixir v1.8 and a Postgres database.

You will need to create a [Strava API Application](https://strava.com/settings/api) to access the API. Any Strava account can be used to create an application. Please refer to the [Strava Developers](http://developers.strava.com/) documentation for help.

### Getting started

1. Install Elixir dependencies:

    ```console
    mix deps.get
    ```

2. Configure your Strava API Application settings:

    ```console
    cp config/dev.secret.example config/dev.secret.exs
    ```

    Edit the `config/dev.secret.exs` config file and enter the Client ID, Client Secret, and Access Token values from you [Strava API Application](https://strava.com/settings/api) settings.

    You will need to do the same for `test.secret.exs` to run tests and `prod.secret.exs` to run in production.

3. Create the event store and read store databases:

    ```console
    mix setup
    ```

    This command will create and initialise two databases (`segmentchallenge_eventstore_dev` and `segmentchallenge_readstore_dev`) using the default Postgres connection settings configured in `config/dev.exs`.

4. Install JavaScript dependencies and compile assets:

    ```console
    npm install
    npm run compile
    ```

    You can use the `npm run watch` task to watch the assets and recompile on change.

4. Run the Phoenix web server:

    ```console
    iex -S mix phx.server
    ```

---

## Useful tasks

### Import active challenge stage efforts

Attempts at active stages are fetched from Strava every four hours. To import them immediately you can run the following from an `iex -S mix` console:

```elixir
iex> SegmentChallenge.Tasks.ImportActiveStageEfforts.execute()
```
