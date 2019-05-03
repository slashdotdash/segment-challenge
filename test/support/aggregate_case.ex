defmodule SegmentChallenge.AggregateCase do
  @moduledoc """
  Defines a test case to be used by aggregate tests.
  """

  use ExUnit.CaseTemplate

  alias Commanded.Aggregate.Multi

  using opts do
    quote location: :keep do
      @aggregate_module unquote(Keyword.get(opts, :aggregate))

      import SegmentChallenge.Factory

      # Assert that the expected events are returned when the given commands
      # have been executed.
      defp assert_events(commands, expected_events) do
        assert_events([], commands, expected_events)
      end

      defp assert_events(initial_events, commands, expected_events) do
        aggregate = evolve(%@aggregate_module{}, build_from_factory(initial_events))

        case execute(commands, aggregate) do
          {:error, reason} ->
            flunk("Failed due to: #{inspect(reason)}")

          {_aggregate, events} ->
            actual_events = List.wrap(events)

            expected_events = build_from_factory(expected_events, actual_events)

            assert actual_events == expected_events
        end
      end

      defp build_from_factory(source, actual \\ []) do
        source
        |> List.wrap()
        |> List.flatten()
        |> Enum.with_index(0)
        |> Enum.map(fn
          {factory, index} when is_function(factory, 1) ->
            actual_event = Enum.at(actual, index)
            refute is_nil(actual_event)

            {name, attrs} = apply(factory, [actual_event])

            build(name, attrs)

          {{name, attrs}, _index} ->
            build(name, attrs)

          {name, _index} when is_atom(name) ->
            build(name)
        end)
      end

      defp assert_error(commands, expected_error) do
        assert_error([], commands, expected_error)
      end

      defp assert_error(initial_events, commands, expected_error) do
        aggregate = evolve(%@aggregate_module{}, build_from_factory(initial_events))

        case execute(commands, aggregate) do
          {:error, reason} = error ->
            assert error == expected_error

          _ ->
            flunk("Expected error #{inspect(expected_error)} but none returned")
        end
      end

      # Execute one or more commands against an aggregate.
      defp execute(commands, aggregate \\ %@aggregate_module{})

      defp execute(commands, aggregate) do
        try do
          commands
          |> build_from_factory()
          |> Enum.reduce({aggregate, []}, fn command, {aggregate, events} ->
            case @aggregate_module.execute(aggregate, command) do
              {:error, _reason} = error ->
                throw(error)

              %Multi{} = multi ->
                case Multi.run(multi) do
                  {:error, _reason} = error ->
                    throw(error)

                  {aggregate, new_events} ->
                    {aggregate, events ++ new_events}
                end

              new_events ->
                {evolve(aggregate, new_events), events ++ List.wrap(new_events)}
            end
          end)
        catch
          {:error, _reason} = reply -> reply
        end
      end

      # Apply the given events to the aggregate's state.
      defp evolve(aggregate, events) do
        events
        |> List.wrap()
        |> Enum.reduce(aggregate, &@aggregate_module.apply(&2, &1))
      end
    end
  end
end
