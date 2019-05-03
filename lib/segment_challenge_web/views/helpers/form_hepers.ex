defmodule SegmentChallengeWeb.Helpers.FormHelpers do
  def field_error_class(field, errors) do
    case has_error?(field, errors) do
      true -> "is-danger"
      _ -> ""
    end
  end

  def display_field_error(field, errors) do
    case field_errors(field, errors) do
      [] -> ""
      errors ->
        errors
        |> Enum.map(fn {:error, _field, _type, message} -> message end)
        |> Enum.join(". ")
    end
  end

  def has_error?(field, errors) do
    Enum.any?(errors, fn error ->
      case error do
        {:error, ^field, _, _} -> true
        _ -> false
      end
    end)
  end

  def field_errors(field, errors) do
    Enum.filter(errors, fn error ->
      case error do
        {:error, ^field, _, _} -> true
        _ -> false
      end
    end)
  end
end
