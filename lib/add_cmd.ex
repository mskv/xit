defmodule Xit.AddCmd do
  @spec call(String.t()) :: :ok | {:error, any}
  def call(path) do
    with {:ok, cwd} <- File.cwd(),
         :ok <- Xit.MiscUtil.ok_or(File.exists?(path), :no_match),
         {:ok, file_paths} <- build_file_paths_to_add(path, cwd),
         {:ok, valid_path} <- Xit.PathUtil.validate_normalize_path(path, cwd),
         {:ok, shas} <- Xit.ObjectRepo.write_blobs_by_paths(file_paths),
         {:ok, index} <- Xit.Index.read() do
      desired_index_entries =
        [file_paths, shas]
        |> Enum.zip()
        |> Enum.map(fn {file_path, sha} -> %Xit.Index.Entry{path: file_path, id: sha} end)

      updated_index = Xit.Index.update_deep(index, valid_path, desired_index_entries)

      Xit.Index.write(updated_index)
    else
      error -> error
    end
  end

  @spec build_file_paths_to_add(String.t(), String.t()) :: {:ok, [String.t()]} | {:error, any}
  defp build_file_paths_to_add(path, cwd) do
    with descended <- file_paths_descended_from_path(path),
         {:ok, normalized} <-
           descended
           |> Enum.map(&Xit.PathUtil.validate_normalize_path(&1, cwd))
           |> Xit.MiscUtil.traverse() do
      {:ok, Enum.reject(normalized, &Xit.PathUtil.path_prefixed_with_base_dir?/1)}
    else
      error -> error
    end
  end

  @spec file_paths_descended_from_path(String.t()) :: [String.t()]
  defp file_paths_descended_from_path(path) do
    if File.exists?(path) && !File.dir?(path) do
      [path]
    else
      :filelib.fold_files(
        String.to_charlist(path),
        '.*',
        true,
        fn file, acc -> [to_string(file) | acc] end,
        []
      )
    end
  end
end
