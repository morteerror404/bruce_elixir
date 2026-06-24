defmodule BruceElixirTest do
  use ExUnit.Case
  doctest BruceElixir

  test "greets the world" do
    assert BruceElixir.hello() == :world
  end
end
