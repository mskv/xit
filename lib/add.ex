defmodule Xit.Add do
  @spec call(String.t()) :: :ok | {:error, any}
  def call(path) do
    with {:ok, valid_path} <- validate_path(path),
         files <- existant_files_descended_from_path(valid_path),
         {:ok, shas} <- Xit.ObjectRepo.persist_blobs_by_paths(files),
         desired_index_entries <-
           Enum.zip(files, shas)
           |> Enum.map(fn {file, sha} -> %Xit.Index.Entry{path: file, id: sha} end),
         :ok <- Xit.Index.update(valid_path, desired_index_entries) do
      :ok
    else
      error -> error
    end
  end

  @spec validate_path(String.t()) :: {:ok, String.t()} | {:error, any}
  defp validate_path(path) do
    with {:ok, path} <- path_within_cwd(path) do
      path_points_at_dir_or_file(path)
    else
      error -> error
    end
  end

  @spec path_within_cwd(String.t()) :: {:ok, String.t()} | {:error, any}
  defp path_within_cwd(path) do
    with {:ok, cwd} <- File.cwd(),
         expanded_path <- Path.expand(path) do
      if String.starts_with?(expanded_path, cwd),
        do: {:ok, expanded_path},
        else: {:error, :path_outside_cwd}
    else
      error -> error
    end
  end

  @spec path_points_at_dir_or_file(String.t()) :: {:ok, String.t()} | {:error, any}
  defp path_points_at_dir_or_file(path) do
    if File.exists?(path), do: {:ok, path}, else: {:error, :no_match}
  end

  @spec existant_files_descended_from_path(String.t()) :: [String.t()]
  defp existant_files_descended_from_path(path) do
    if File.exists?(path) && !File.dir?(path) do
      [path]
    else
      :filelib.fold_files(
        String.to_charlist(path),
        '.*',
        true,
        fn file, acc -> [file | acc] end,
        []
      )
    end
  end
end
