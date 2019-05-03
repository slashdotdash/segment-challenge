defmodule SegmentChallenge.Serialization.Helpers do
  def to_atom(nil, default), do: default
  def to_atom("", default), do: default
  def to_atom(string, _default) when is_binary(string), do: String.to_existing_atom(string)

  def to_decimal(nil), do: nil
  def to_decimal(number) when is_integer(number), do: Decimal.new(number)
  def to_decimal(number) when is_float(number), do: Decimal.from_float(number)
  def to_decimal(number) when is_binary(number), do: Decimal.new(number)
end
