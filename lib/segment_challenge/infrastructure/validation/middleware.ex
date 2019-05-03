defmodule SegmentChallenge.Infrastructure.Validation.Middleware do
  @behaviour Commanded.Middleware

  require Logger

  alias Commanded.Middleware.Pipeline
  import Pipeline

  def before_dispatch(%Pipeline{} = pipeline) do
    %Pipeline{command: command} = pipeline

    case Vex.valid?(command) do
      true -> pipeline
      false -> failed_validation(pipeline)
    end
  end

  def after_dispatch(pipeline), do: pipeline
  def after_failure(pipeline), do: pipeline

  defp failed_validation(%Pipeline{} = pipeline) do
    %Pipeline{command: command} = pipeline

    errors = Vex.errors(command)

    Logger.warn(fn ->
      "Command #{inspect(command.__struct__)} failed validation, errors: #{inspect(errors)}, command: " <>
        inspect(command)
    end)

    pipeline
    |> respond({:error, {:validation_failure, errors}})
    |> halt()
  end
end
