defmodule XitTest do
  use ExUnit.Case
  doctest Xit

  test "greets the world" do
    assert Xit.hello() == :world
  end
end
