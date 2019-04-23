defmodule Xit.IndexMeta do
  # example: %{"some/file" => "<sha>"}
  @type path_to_file_id_map :: %{required(String.t()) => String.t()}

  # example: %{"" => MapSet<["some"]>, "some" => MapSet<["some/file"]>}
  # note that the content paths are not relative to the containing directory
  @type dir_to_content_paths_map :: %{required(String.t()) => MapSet.t(String.t())}

  @type t :: {path_to_file_id_map, dir_to_content_paths_map}

  @spec build(Xit.Index.t()) :: t
  def build(index) do
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
end
