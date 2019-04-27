defmodule Xit.IndexMeta do
  # map of file paths to file ids
  # example: %{"some/file" => "<sha>"}
  @type file_meta :: %{required(String.t()) => String.t()}

  # map of dir paths to sets containing the file and dir paths in given dirs
  # example: %{"" => MapSet<["some"]>, "some" => MapSet<["some/file"]>}
  # note that the content paths are not relative to the containing directory
  @type dir_meta :: %{required(String.t()) => MapSet.t(String.t())}

  # index meta consists of both file and dir meta
  @type t :: {file_meta, dir_meta}

  @spec build(Xit.Index.t()) :: t
  def build(index) do
    Enum.reduce(
      index.entries,
      {%{}, %{}},
      fn entry, {file_meta, dir_meta} ->
        {
          Map.put(file_meta, entry.path, entry.id),
          update_dir_meta(dir_meta, entry.path)
        }
      end
    )
  end

  @spec update_dir_meta(dir_meta, String.t()) :: dir_meta
  defp update_dir_meta(dir_meta, path) do
    path_split = String.split(path, "/")

    {new_dir_meta, _} =
      Enum.reduce(
        path_split,
        {dir_meta, ""},
        fn path_part, {dir_meta, path_so_far} ->
          absolute_part_path = Path.join(path_so_far, path_part)

          {
            Map.update(
              dir_meta,
              path_so_far,
              MapSet.new([absolute_part_path]),
              &MapSet.put(&1, absolute_part_path)
            ),
            absolute_part_path
          }
        end
      )

    new_dir_meta
  end
end
