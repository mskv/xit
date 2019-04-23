defmodule XitWriteTreeFromIndexTest do
  use ExUnit.Case
  doctest Xit.WriteTreeFromIndex

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  test ~S"""
    reports that it had been called with an empty index
  """ do
    {:ok, :initialized} = Xit.InitCmd.call()

    index = %Xit.Index{entries: []}

    result = Xit.WriteTreeFromIndex.call(index)
    assert(result === {:error, :empty_index})
  end

  test ~S"""
    Represents the index contents as tree objects identified by their SHAs
  """ do
    {:ok, :initialized} = Xit.InitCmd.call()

    first_root_entry = %Xit.Index.Entry{path: "first_entry.ex", id: "1"}
    second_root_entry = %Xit.Index.Entry{path: "second_entry.ex", id: "2"}
    first_nested_entry = %Xit.Index.Entry{path: "nested/first_entry.ex", id: "3"}
    second_nested_entry = %Xit.Index.Entry{path: "nested/second_entry.ex", id: "4"}
    first_double_nested_entry = %Xit.Index.Entry{path: "nested/double/first_entry.ex", id: "5"}
    second_double_nested_entry = %Xit.Index.Entry{path: "nested/double/second_entry.ex", id: "6"}
    deeply_nested_entry = %Xit.Index.Entry{path: "very/deeply/nested/entry.ex", id: "7"}

    entries = [
      first_root_entry,
      second_root_entry,
      first_nested_entry,
      second_nested_entry,
      first_double_nested_entry,
      second_double_nested_entry,
      deeply_nested_entry
    ]

    index = %Xit.Index{entries: entries}

    {:ok, root_sha} = Xit.WriteTreeFromIndex.call(index)

    root_tree = :erlang.binary_to_term(File.read!(".xit/objects/#{root_sha}"))

    check_tree_contents(root_tree, [
      {"first_entry.ex", "1"},
      {"second_entry.ex", "2"},
      {"nested", nil},
      {"very", nil}
    ])
    |> assert

    nested_tree_sha = find_edge_sha(root_tree, "nested")
    nested_tree = :erlang.binary_to_term(File.read!(".xit/objects/#{nested_tree_sha}"))

    check_tree_contents(nested_tree, [
      {"first_entry.ex", "3"},
      {"second_entry.ex", "4"},
      {"double", nil}
    ])
    |> assert

    nested_double_tree_sha = find_edge_sha(nested_tree, "double")
    nested_double_tree = :erlang.binary_to_term(File.read!(".xit/objects/#{nested_double_tree_sha}"))

    check_tree_contents(nested_double_tree, [{"first_entry.ex", "5"}, {"second_entry.ex", "6"}])
    |> assert

    very_tree_sha = find_edge_sha(root_tree, "very")
    very_tree = :erlang.binary_to_term(File.read!(".xit/objects/#{very_tree_sha}"))

    check_tree_contents(very_tree, [{"deeply", nil}]) |> assert

    very_deeply_tree_sha = find_edge_sha(very_tree, "deeply")
    very_deeply_tree = :erlang.binary_to_term(File.read!(".xit/objects/#{very_deeply_tree_sha}"))

    check_tree_contents(very_deeply_tree, [{"nested", nil}]) |> assert

    very_deeply_nested_tree_sha = find_edge_sha(very_deeply_tree, "nested")
    very_deeply_nested_tree = :erlang.binary_to_term(File.read!(".xit/objects/#{very_deeply_nested_tree_sha}"))

    check_tree_contents(very_deeply_nested_tree, [{"entry.ex", "7"}]) |> assert
  end

  defp find_edge_sha(tree = %Xit.Tree{}, path) do
    Enum.find(tree.edges, &(&1.path === path)).id
  end

  defp check_tree_contents(tree, contents) do
    length(tree.edges) === length(contents) and
      Enum.all?(contents, fn {path, id} ->
        Enum.any?(tree.edges, &(&1.path === path and (!id or &1.id === id)))
      end)
  end
end
