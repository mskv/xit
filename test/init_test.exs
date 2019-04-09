defmodule XitInitTest do
  use ExUnit.Case
  doctest Xit.Init

  setup do
    Support.Fs.setup()
    on_exit(fn -> Support.Fs.cleanup() end)
    assert(File.ls!() === [])
    :ok
  end

  test "when running in an empty directory, initializes it" do
    {:ok, :initialized} = Xit.Init.call()
    assert_repository_initialized()
  end

  test "when there is already a repository threre, reinitializes it" do
    File.mkdir!(".xit")
    {:ok, :reinitialized} = Xit.Init.call()
    assert_repository_initialized()
  end

  defp assert_repository_initialized do
    assert(File.ls!() === [".xit"])
    assert(File.ls!(".xit") === ["objects"])
  end
end
