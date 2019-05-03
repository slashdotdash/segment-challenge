# Segment Challenge

Segment Challenge is an Elixir Phoenix web application built using [Commanded](https://github.com/commanded/commanded) for CQRS/ES. The front-end is mostly server generated HTML plus a few React components for responsive forms.

## Prerequisites

Install Elixir v1.8 and a Postgres database.

You will need to create a [Strava API Application](https://strava.com/settings/api) to access the API. Any Strava account can be used to create an application. Please refer to the [Strava Developers](http://developers.strava.com/) documentation for help.

## Getting started

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
