defmodule PhailTest do
  use ExUnit.Case
  doctest Phail

  test "greets the world" do
    assert Phail.hello() == :world
  end
end
