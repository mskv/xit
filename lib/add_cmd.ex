defmodule Xit.AddCmd do
  @spec call(String.t()) :: :ok | {:error, any}
  def call(path) do
    with {:ok, cwd} <- File.cwd(),
         :ok <- File.exists?(path) |> Xit.MiscUtil.ok_or(:no_match),
         {:ok, working_dir_file_paths} <- Xit.PathUtil.normalized_working_dir_paths(cwd, path),
         {:ok, valid_path} <- Xit.PathUtil.validate_normalize_path(path, cwd),
         {:ok, shas} <- working_dir_file_paths |> Xit.MiscUtil.map_traverse_p(&write_blob/1),
         {:ok, index} <- Xit.Index.read() do
      desired_index_entries =
        Enum.zip(working_dir_file_paths, shas)
        |> Enum.map(fn {file_path, sha} -> %Xit.Index.Entry{path: file_path, id: sha} end)

      updated_index = Xit.Index.update_deep(index, valid_path, desired_index_entries)

      Xit.Index.write(updated_index)
    else
      error -> error
    end
  end

  @spec write_blob(String.t()) :: {:ok, String.t()} | {:error, any}
  defp write_blob(path) do
    with {:ok, content} <- File.read(path) do
      Xit.Blob.new(content) |> Xit.ObjectRepo.write()
    else
      error -> error
    end
  end
end
