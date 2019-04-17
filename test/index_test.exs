defmodule XitIndexTest do
  use ExUnit.Case
  doctest Xit.Index

  setup do
    Support.Fs.setup()
    on_exit(fn -> Support.Fs.cleanup() end)
    assert(File.ls!() === [])
    :ok
  end

  test "when the index file does not exist, failes" do
    {:error, :enoent} = Xit.Index.update(".", [])
  end

  test "when an empty index file exists, fills it with serialized content" do
    path = "."
    desired_entries = [%Xit.Index.Entry{path: "path", id: "1"}]

    {:ok, :initialized} = Xit.Init.call()
    create_empty_index_file()
    :ok = Xit.Index.update(path, desired_entries)

    assert(index_file_contains(desired_entries))
  end

  test """
    when an index file has entries under different path,
    the new entries get appended to the index
  """ do
    existant_entries = [%Xit.Index.Entry{path: "lib/1.ex", id: "1"}]
    path = "test"
    desired_entries = [%Xit.Index.Entry{path: "test/1.ex", id: "2"}]

    {:ok, :initialized} = Xit.Init.call()
    create_filled_index_file(existant_entries)
    :ok = Xit.Index.update(path, desired_entries)

    assert(index_file_contains(existant_entries ++ desired_entries))
  end

  test """
    when an index file has entries under same path,
    the new entries get replace the old ones
  """ do
    existant_non_conflicting_entry = %Xit.Index.Entry{path: "lib/1.ex", id: "1"}
    existant_conflicting_entry = %Xit.Index.Entry{path: "test/1.ex", id: "2"}

    existant_entries = [
      existant_non_conflicting_entry,
      existant_conflicting_entry
    ]

    path = "test"
    desired_entry = %Xit.Index.Entry{path: "test/1.ex", id: "3"}

    {:ok, :initialized} = Xit.Init.call()
    create_filled_index_file(existant_entries)
    :ok = Xit.Index.update(path, [desired_entry])

    assert(
      index_file_contains([
        existant_non_conflicting_entry,
        desired_entry
      ])
    )
  end

  test """
    when an index file has entries that no longer exist among the new
    desired list, they get deleted
  """ do
    existant_non_conflicting_entry = %Xit.Index.Entry{path: "lib/1.ex", id: "1"}
    existant_entry_to_be_deleted = %Xit.Index.Entry{path: "test/1.ex", id: "2"}
    existant_conflicting_entry = %Xit.Index.Entry{path: "test/2.ex", id: "3"}

    existant_entries = [
      existant_non_conflicting_entry,
      existant_entry_to_be_deleted,
      existant_conflicting_entry
    ]

    path = "test"
    desired_entry = %Xit.Index.Entry{path: "test/2.ex", id: "4"}

    {:ok, :initialized} = Xit.Init.call()
    create_filled_index_file(existant_entries)
    :ok = Xit.Index.update(path, [desired_entry])

    assert(
      index_file_contains([
        existant_non_conflicting_entry,
        desired_entry
      ])
    )
  end

  defp create_empty_index_file do
    File.touch!(Xit.Constants.index_path())
  end

  defp create_filled_index_file(entries) do
    %Xit.Index{entries: entries}
    |> :erlang.term_to_binary()
    |> (&File.write!(Xit.Constants.index_path(), &1)).()
  end

  defp index_file_contains(entries) do
    File.read!(Xit.Constants.index_path())
    |> :erlang.binary_to_term()
    |> (& &1.entries).()
    |> Support.Util.lists_eq_irrespective_of_order(entries)
  end
end
