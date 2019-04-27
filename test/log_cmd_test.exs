defmodule XitLogCmdTest do
  use ExUnit.Case
  doctest Xit.LogCmd

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  test "returns an empty list when HEAD points at nothing" do
    {:ok, :initialized} = Xit.InitCmd.call()

    {:ok, log} = Xit.LogCmd.call()
    assert(log === [])
  end

  test """
    returns commit history from newest commit to oldest when HEAD points at something
  """ do
    {:ok, :initialized} = Xit.InitCmd.call()

    root_commit = Xit.Commit.new("", [])
    {:ok, root_commit_sha} = Xit.ObjectRepo.write(root_commit)

    first_child_commit = Xit.Commit.new("", [root_commit_sha])
    {:ok, first_child_commit_sha} = Xit.ObjectRepo.write(first_child_commit)

    second_child_commit = Xit.Commit.new("", [first_child_commit_sha])
    {:ok, second_child_commit_sha} = Xit.ObjectRepo.write(second_child_commit)

    :ok = Xit.Head.write(first_child_commit_sha)

    {:ok, log} = Xit.LogCmd.call()
    assert(log === [first_child_commit_sha, root_commit_sha])
  end
end
