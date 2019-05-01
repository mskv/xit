defmodule XitReadTreeToIndexTest do
  use ExUnit.Case
  doctest Xit.ReadTreeToIndex

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  test ~S"""
    reading into an empty index populates it
  """ do
    {:ok, :initialized} = Xit.Cmd.Init.call()
    mock_index = populate_mock_index()
    {:ok, root_tree_sha} = Xit.WriteTreeFromIndex.call(mock_index)

    empty_index = %Xit.Index{entries: []}
    {:ok, index} = Xit.ReadTreeToIndex.call(empty_index, root_tree_sha)

    Support.Util.lists_eq_irrespective_of_order(index.entries, mock_index.entries)
    |> assert
  end

  test ~S"""
    reading into an index that already has some entries under read paths
    overwrites those entries and appends the rest
  """ do
    {:ok, :initialized} = Xit.Cmd.Init.call()
    mock_index = populate_mock_index()
    {:ok, root_tree_sha} = Xit.WriteTreeFromIndex.call(mock_index)

    partially_matching_index = %Xit.Index{
      entries: [
        %Xit.Index.Entry{path: "first_nested/file_second", id: "some_id"},
        %Xit.Index.Entry{path: "root_file_first", id: "some_other_id"}
      ]
    }

    {:ok, index} = Xit.ReadTreeToIndex.call(partially_matching_index, root_tree_sha)

    Support.Util.lists_eq_irrespective_of_order(index.entries, mock_index.entries)
    |> assert
  end

  test ~S"""
    reading into an index that has some entries under different paths
    deletes all entries that are not among the read ones
  """ do
    {:ok, :initialized} = Xit.Cmd.Init.call()
    mock_index = populate_mock_index()
    {:ok, root_tree_sha} = Xit.WriteTreeFromIndex.call(mock_index)

    index_with_superfluous_entries = %Xit.Index{
      entries: [
        %Xit.Index.Entry{path: "double/nested/superfluous", id: "1"},
        %Xit.Index.Entry{path: "nested/superfluous", id: "2"},
        %Xit.Index.Entry{path: "root_superfluous", id: "3"},
        %Xit.Index.Entry{path: "first_nested/superfluous", id: "4"},
        %Xit.Index.Entry{path: "first_nested/double_nested/superflouous", id: "5"}
      ]
    }

    {:ok, index} = Xit.ReadTreeToIndex.call(index_with_superfluous_entries, root_tree_sha)

    Support.Util.lists_eq_irrespective_of_order(index.entries, mock_index.entries)
    |> assert
  end

  defp populate_mock_index do
    blob_paths = [
      "root_file_first",
      "root_file_second",
      "first_nested/file_first",
      "first_nested/file_second",
      "first_nested/double_nested/file",
      "second_nested/file"
    ]

    blobs = Enum.map(blob_paths, &%Xit.Blob{content: "#{&1}_content"})
    blob_shas = Enum.map(blobs, &Xit.ObjectRepo.write!/1)

    index_entries =
      [blob_paths, blob_shas]
      |> Enum.zip()
      |> Enum.map(fn {blob_path, blob_sha} ->
        %Xit.Index.Entry{path: blob_path, id: blob_sha}
      end)

    %Xit.Index{entries: index_entries}
  end
end
