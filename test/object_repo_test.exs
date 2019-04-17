defmodule XitObjectRepoTest do
  use ExUnit.Case
  doctest Xit.ObjectRepo

  setup do
    Support.Fs.setup()
    on_exit(&Support.Fs.cleanup/0)
    assert(File.ls!() === [])
    :ok
  end

  describe "#persist_blobs_by_paths" do
    test ~S"""
      Persists each blob in its own file identified by the SHA
      of the file's content.
    """ do
      files = [
        %{path: "test1/path", content: "test1/content"},
        %{path: "test2/path", content: "test2/content"}
      ]

      Enum.each(files, fn %{:path => path, :content => content} ->
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, content)
      end)

      {:ok, :initialized} = Xit.Init.call()
      {:ok, shas} = Xit.ObjectRepo.persist_blobs_by_paths(Enum.map(files, & &1[:path]))

      persisted_paths = Enum.map(shas, &".xit/objects/#{&1}")

      peristed_files =
        Enum.zip([files, shas, persisted_paths])
        |> Enum.map(fn {file, sha, persisted_path} ->
          Map.merge(file, %{sha: sha, persisted_path: persisted_path})
        end)

      Enum.each(peristed_files, fn %{:persisted_path => persisted_path} ->
        assert(File.exists?(persisted_path))
      end)

      Enum.each(peristed_files, fn %{:content => content, :persisted_path => persisted_path} ->
        persisted_content = File.read!(persisted_path)
        assert(:erlang.binary_to_term(persisted_content) === %Xit.Blob{content: content})
      end)
    end
  end
end
