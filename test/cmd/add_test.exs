defmodule XitCmdAddTest do
  use ExUnit.Case
  doctest Xit.Cmd.Add

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  @tag skip: "todo"
  test "when run without an initialized repository, informs about it" do
  end

  test "when given path outside the current working directory, informs about it" do
    {:ok, :initialized} = Xit.Cmd.Init.call()

    {:error, :path_outside_cwd} = Xit.Cmd.Add.call("..")
  end

  test "when given non existant path, informs about it" do
    {:ok, :initialized} = Xit.Cmd.Init.call()

    {:error, :no_match} = Xit.Cmd.Add.call("test")
  end
end
