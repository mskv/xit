defmodule XitIndexTest do
  use ExUnit.Case
  doctest Xit.Index

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  describe "#update_deep" do
    test "when index is empty, fills it with desired entries" do
      index = %Xit.Index{entries: []}
      path = "."
      desired_entries = [%Xit.Index.Entry{path: "path", id: "1"}]

      updated_index = Xit.Index.update_deep(index, path, desired_entries)

      assert(index_file_contains(updated_index, desired_entries))
    end

    test """
      when index has entries under different path,
      the new entries get appended to the index
    """ do
      existant_entries = [%Xit.Index.Entry{path: "lib/1.ex", id: "1"}]
      index = %Xit.Index{entries: existant_entries}
      path = "test"
      desired_entries = [%Xit.Index.Entry{path: "test/1.ex", id: "2"}]

      updated_index = Xit.Index.update_deep(index, path, desired_entries)

      assert(index_file_contains(updated_index, existant_entries ++ desired_entries))
    end

    test """
      when index file has entries under same path,
      the new entries replace the old ones
    """ do
      existant_non_conflicting_entry = %Xit.Index.Entry{path: "lib/1.ex", id: "1"}
      existant_conflicting_entry = %Xit.Index.Entry{path: "test/1.ex", id: "2"}

      existant_entries = [
        existant_non_conflicting_entry,
        existant_conflicting_entry
      ]

      index = %Xit.Index{entries: existant_entries}
      path = "test"
      desired_entry = %Xit.Index.Entry{path: "test/1.ex", id: "3"}

      updated_index = Xit.Index.update_deep(index, path, [desired_entry])

      assert(
        index_file_contains(updated_index, [
          existant_non_conflicting_entry,
          desired_entry
        ])
      )
    end

    test """
      when index has entries that no longer exist among the new
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

      index = %Xit.Index{entries: existant_entries}
      path = "test"
      desired_entry = %Xit.Index.Entry{path: "test/2.ex", id: "4"}

      updated_index = Xit.Index.update_deep(index, path, [desired_entry])

      assert(
        index_file_contains(updated_index, [
          existant_non_conflicting_entry,
          desired_entry
        ])
      )
    end
  end

  defp index_file_contains(index, entries) do
    Support.Util.lists_eq_irrespective_of_order(index.entries, entries)
  end
end
