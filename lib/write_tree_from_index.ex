defmodule Xit.WriteTreeFromIndex do
  @doc """
  The goal is to create a tree from the given `index`. We make use of
  Xit.IndexMeta and recursively walk the directory tree, persisting all
  the blobs we encounter and creating Xit.Tree for each directory we see.
  """
  @spec call(Xit.Index.t()) :: {:ok, String.t()} | {:error, any}
  def call(index) do
    with :ok <- ensure_non_empty_index(index) do
      index_meta = Xit.IndexMeta.build(index)
      write_path_from_index_meta(index_meta, "")
    end
  end

  @spec ensure_non_empty_index(Xit.Index.t()) :: :ok | {:error, :empty_index}
  defp ensure_non_empty_index(index) do
    if length(index.entries) > 0, do: :ok, else: {:error, :empty_index}
  end

  @spec write_path_from_index_meta(Xit.IndexMeta.t(), String.t()) :: {:ok, String.t()} | {:error, any}
  defp write_path_from_index_meta(index_meta = {file_meta, dir_meta}, path) do
    content_paths = Map.get(dir_meta, path)

    {file_paths, dir_paths} = partition_dir_content_paths(file_meta, content_paths)

    file_shas = file_paths |> Enum.map(fn path -> Map.get(file_meta, path) end)

    persist_dirs =
      Xit.Helpers.map_traverse_parallel(
        dir_paths,
        fn path -> write_path_from_index_meta(index_meta, path) end
      )

    with {:ok, dir_shas} <- persist_dirs do
      tree_edges =
        Enum.concat([
          Enum.zip([dir_paths, dir_shas]),
          Enum.zip([file_paths, file_shas])
        ])
        |> Enum.map(fn {edge_path, edge_sha} ->
          %Xit.Tree.Edge{path: Path.relative_to(edge_path, path), id: edge_sha}
        end)

      tree = %Xit.Tree{edges: tree_edges}
      Xit.ObjectRepo.write(tree)
    end
  end

  @spec partition_dir_content_paths(
          Xit.IndexMeta.file_meta(),
          MapSet.t(String.t())
        ) :: {[String.t()], [String.t()]}
  defp partition_dir_content_paths(file_meta, content_paths) do
    Enum.reduce(content_paths, {[], []}, fn path, {file_paths, dir_paths} ->
      if Map.has_key?(file_meta, path),
        do: {[path | file_paths], dir_paths},
        else: {file_paths, [path | dir_paths]}
    end)
  end
end
