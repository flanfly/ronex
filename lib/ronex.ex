defmodule Ronex do
  @moduledoc """
  Documentation for Ronex.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Ronex.hello()
      :world

  """
  def receive(objects, frame) do
    UUID.now()
  end
end
