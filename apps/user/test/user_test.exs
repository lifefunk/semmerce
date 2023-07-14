defmodule UserTest do
  use ExUnit.Case
  doctest User

  test "greets the world" do
    assert User.hello() == :world
  end
end
