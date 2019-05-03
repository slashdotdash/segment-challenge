defmodule SegmentChallenge.Infrastructure.FunctionEncoder do
  defimpl Jason.Encoder, for: Function do
    def encode(data, options) when is_function(data) do
      {:arity, arity} = Function.info(data, :arity)

      Jason.Encode.string("Function/#{arity}", options)
    end
  end
end
