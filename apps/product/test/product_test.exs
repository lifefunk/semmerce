defmodule ProductTest do
  use ExUnit.Case
  doctest Product

  test "greets the world" do
    assert Product.hello() == :world
  end
end
