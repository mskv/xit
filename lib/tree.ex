defmodule Xit.Tree do
  defmodule Edge do
    @enforce_keys [:path, :id]
    defstruct [:path, :id]

    @type t :: %__MODULE__{
            path: String.t(),
            id: String.t()
          }
  end

  @enforce_keys [:edges]
  defstruct [:edges]

  @type t :: %__MODULE__{
          edges: list(Edge.t())
        }

  # example: %{"some/file" => "<sha>"}
  @type path_to_file_id_map :: %{required(String.t()) => String.t()}

  # example: %{"" => MapSet<["some"]>, "some" => MapSet<["some/file"]>}
  # note that the content paths are not relative to the containing directory
  @type dir_to_content_paths_map :: %{required(String.t()) => MapSet.t(String.t())}

  @type index_metadata :: {path_to_file_id_map, dir_to_content_paths_map}

  @spec write_from_index(Xit.Index.t()) :: {:ok, String.t()} | {:error, any}
  def write_from_index(index) do
    with :ok <- ensure_non_empty_index(index) do
      index_metadata = build_index_metadata(index)
      write_path_from_index_metadata(index_metadata, "")
    else
      error -> error
    end
  end

  @spec ensure_non_empty_index(Xit.Index.t()) :: :ok | {:error, :empty_index}
  defp ensure_non_empty_index(index) do
    if length(index.entries) > 0, do: :ok, else: {:error, :empty_index}
  end

  @spec build_index_metadata(Xit.Index.t()) :: index_metadata
  defp build_index_metadata(index) do
    index.entries
    |> Enum.reduce(
      {%{}, %{}},
      fn entry, {path_to_file_id_map, dir_to_content_paths_map} ->
        {
          Map.put(path_to_file_id_map, entry.path, entry.id),
          update_dir_to_content_paths_map(dir_to_content_paths_map, entry.path)
        }
      end
    )
  end

  @spec update_dir_to_content_paths_map(dir_to_content_paths_map, String.t()) :: dir_to_content_paths_map
  defp update_dir_to_content_paths_map(dir_to_content_paths_map, path) do
    path_split = String.split(path, "/")

    {new_dir_to_content_paths_map, _} =
      Enum.reduce(
        path_split,
        {dir_to_content_paths_map, ""},
        fn path_part, {dir_to_content_paths_map, path_so_far} ->
          absolute_part_path = Path.join(path_so_far, path_part)

          {
            Map.update(
              dir_to_content_paths_map,
              path_so_far,
              MapSet.new([absolute_part_path]),
              &MapSet.put(&1, absolute_part_path)
            ),
            absolute_part_path
          }
        end
      )

    new_dir_to_content_paths_map
  end

  @spec write_path_from_index_metadata(index_metadata, String.t()) :: {:ok, String.t()} | {:error, any}
  defp write_path_from_index_metadata(index_metadata = {path_to_file_id_map, dir_to_content_paths_map}, path) do
    content_paths = Map.get(dir_to_content_paths_map, path)

    {file_paths, dir_paths} = partition_dir_content_paths(path_to_file_id_map, content_paths)

    file_shas = file_paths |> Enum.map(fn path -> Map.get(path_to_file_id_map, path) end)

    persist_dirs =
      dir_paths
      |> Enum.map(fn path -> Task.async(fn -> write_path_from_index_metadata(index_metadata, path) end) end)
      |> Enum.map(&Task.await/1)
      |> List.foldr({:ok, []}, fn result, acc ->
        with {:ok, shas} <- acc,
             {:ok, sha} <- result do
          {:ok, [sha | shas]}
        else
          error -> error
        end
      end)

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
      Xit.ObjectRepo.persist_object(tree)
    else
      error -> error
    end
  end

  @spec partition_dir_content_paths(path_to_file_id_map, MapSet.t(String.t())) :: {[String.t()], [String.t()]}
  defp partition_dir_content_paths(path_to_file_id_map, content_paths) do
    Enum.reduce(content_paths, {[], []}, fn path, {file_paths, dir_paths} ->
      if Map.has_key?(path_to_file_id_map, path),
        do: {[path | file_paths], dir_paths},
        else: {file_paths, [path | dir_paths]}
    end)
  end
end
