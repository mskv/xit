defmodule XitCheckoutIndex do
  use ExUnit.Case
  doctest Xit.CheckoutIndex

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  test """
    when the index is empty, clears the working directory
  """ do
    {:ok, :initialized} = Xit.InitCmd.call()

    # working directory
    File.write!("root_file", "test")
    File.mkdir!("root_dir")
    File.write!("root_dir/nested_file", "test")

    # index
    index = %Xit.Index{entries: []}

    :ok = Xit.CheckoutIndex.call(index)

    assert(File.ls!() -- [".xit"] === [])
  end

  test """
    when the index has some overlap, deletes the non-overlapping entries
  """ do
    {:ok, :initialized} = Xit.InitCmd.call()

    # working directory
    File.write!("root_file", "test")
    File.mkdir!("first_root_dir")
    File.write!("first_root_dir/second_nested_file", "test")
    File.mkdir!("second_root_dir")
    File.write!("second_root_dir/file", "test")

    # index
    File.write!("first_root_dir/first_nested_file", "test")
    sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "test"})

    index = %Xit.Index{
      entries: [
        %Xit.Index.Entry{path: "first_root_dir/first_nested_file", id: sha}
      ]
    }

    :ok = Xit.CheckoutIndex.call(index)

    assert(File.ls!() -- [".xit"] === ["first_root_dir"])
    assert(File.ls!("first_root_dir") === ["first_nested_file"])
  end

  test """
    when the index contains new files, inserts them
  """ do
    {:ok, :initialized} = Xit.InitCmd.call()

    # working directory
    File.write!("root_file", "root_file")
    File.mkdir!("root_dir")
    File.write!("root_dir/nested_file", "nested_file")

    # index
    root_file_sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "root_file"})
    nested_file_sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "nested_file"})
    root_indexed_file_sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "root_indexed_file"})
    root_dir_nested_indexed_file_sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "root_dir/nested_indexed_file"})
    indexed_dir_indexed_file_sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "indexed_dir/indexed_file"})

    index = %Xit.Index{
      entries: [
        %Xit.Index.Entry{path: "root_file", id: root_file_sha},
        %Xit.Index.Entry{path: "root_dir/nested_file", id: nested_file_sha},
        %Xit.Index.Entry{path: "root_indexed_file", id: root_indexed_file_sha},
        %Xit.Index.Entry{path: "root_dir/nested_indexed_file", id: root_dir_nested_indexed_file_sha},
        %Xit.Index.Entry{path: "indexed_dir/indexed_file", id: indexed_dir_indexed_file_sha}
      ]
    }

    :ok = Xit.CheckoutIndex.call(index)

    Support.Util.lists_eq_irrespective_of_order(File.ls!() -- [".xit"], [
      "root_file",
      "root_dir",
      "indexed_dir",
      "root_indexed_file"
    ])
    |> assert

    Support.Util.lists_eq_irrespective_of_order(File.ls!("root_dir"), [
      "nested_file",
      "nested_indexed_file"
    ])
    |> assert

    Support.Util.lists_eq_irrespective_of_order(File.ls!("indexed_dir"), [
      "indexed_file"
    ])
    |> assert
  end

  test """
    when the index contains files that are different, updates them
  """ do
    {:ok, :initialized} = Xit.InitCmd.call()

    # working directory
    File.write!("root_file", "root_file")
    File.mkdir!("root_dir")
    File.write!("root_dir/nested_file", "nested_file")

    # index
    root_file_sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "root_file"})
    nested_file_sha = Xit.ObjectRepo.write!(%Xit.Blob{content: "nested_file_changed"})

    index = %Xit.Index{
      entries: [
        %Xit.Index.Entry{path: "root_file", id: root_file_sha},
        %Xit.Index.Entry{path: "root_dir/nested_file", id: nested_file_sha}
      ]
    }

    :ok = Xit.CheckoutIndex.call(index)

    Support.Util.lists_eq_irrespective_of_order(File.ls!() -- [".xit"], [
      "root_file",
      "root_dir"
    ])
    |> assert

    Support.Util.lists_eq_irrespective_of_order(File.ls!("root_dir"), [
      "nested_file"
    ])
    |> assert

    assert(File.read!("root_file") === "root_file")
    assert(File.read!("root_dir/nested_file") === "nested_file_changed")
  end
end
