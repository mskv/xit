defmodule XitCommitCmdTest do
  use ExUnit.Case
  doctest Xit.CommitCmd

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  @tag skip: "todo"
  test "when run without an initialized repository, informs about it" do
  end

  test "when index is empty, informs about it" do
    {:ok, :initialized} = Xit.InitCmd.call()

    {:error, :empty_index} = Xit.CommitCmd.call()
  end

  test "when head is empty, creates a root commit and points head at it" do
    {:ok, :initialized} = Xit.InitCmd.call()
    File.touch!("test")
    :ok = Xit.AddCmd.call(".")
    :ok = Xit.CommitCmd.call()

    head = File.read!(".xit/HEAD")
    commit = :erlang.binary_to_term(File.read!(".xit/objects/#{head}"))
    assert(commit.parents === [])
    tree = :erlang.binary_to_term(File.read!(".xit/objects/#{commit.tree}"))
    assert(length(tree.edges) === 1)
    assert(List.first(tree.edges).path === "test")
  end

  test "when head is non-empty, creates a child commit referencing the parent and points head at it" do
    {:ok, :initialized} = Xit.InitCmd.call()
    File.touch!("test")
    :ok = Xit.AddCmd.call(".")
    File.write!(".xit/HEAD", "parent_sha")
    :ok = Xit.CommitCmd.call()

    head = File.read!(".xit/HEAD")
    commit = :erlang.binary_to_term(File.read!(".xit/objects/#{head}"))
    assert(commit.parents === ["parent_sha"])
    tree = :erlang.binary_to_term(File.read!(".xit/objects/#{commit.tree}"))
    assert(length(tree.edges) === 1)
    assert(List.first(tree.edges).path === "test")
  end
end
