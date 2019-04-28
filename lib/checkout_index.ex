defmodule Xit.CheckoutIndex do
  @spec call(Xit.Index.t()) :: :ok | {:error, any}
  def call(index) do
    with {:ok, cwd} <- File.cwd(),
         {:ok, working_dir_file_paths} <- Xit.PathUtil.normalized_working_dir_paths(cwd),
         {:ok, working_dir_index} = build_index(working_dir_file_paths) do
      index_meta = Xit.IndexMeta.build(index)
      {file_meta, _dir_meta} = index_meta
      working_dir_index_meta = Xit.IndexMeta.build(working_dir_index)

      {files_to_delete, dirs_to_delete, files_to_upsert} =
        Xit.IndexMeta.compare_indices(working_dir_index_meta, index_meta)

      with :ok <- delete_files(files_to_delete),
           :ok <- delete_dirs(dirs_to_delete),
           :ok <- write_files(files_to_upsert, file_meta) do
        :ok
      else
        error -> error
      end
    else
      error -> error
    end
  end

  @spec build_index([String.t()]) :: {:ok, Xit.Index.t()} | {:error, any}
  defp build_index(file_paths) do
    with {:ok, ids} <- Xit.MiscUtil.map_traverse_p(file_paths, &get_file_blob_id/1) do
      index_entries =
        Enum.zip(file_paths, ids)
        |> Enum.map(fn {path, id} -> %Xit.Index.Entry{path: path, id: id} end)

      {:ok, %Xit.Index{entries: index_entries}}
    else
      error -> error
    end
  end

  @spec get_file_blob_id(String.t()) :: {:ok, String.t()} | {:error, any}
  defp get_file_blob_id(file_path) do
    with {:ok, content} <- File.read(file_path) do
      {:ok, Xit.Blob.new(content) |> Xit.ObjectRepo.serialize_and_get_id() |> elem(0)}
    else
      error -> error
    end
  end

  @spec delete_files([String.t()]) :: :ok | {:error, any}
  defp delete_files(paths) do
    paths
    |> Xit.MiscUtil.map_p(&File.rm/1)
    |> Xit.MiscUtil.traverse_simple()
  end

  @spec delete_dirs([String.t()]) :: :ok | {:error, any}
  defp delete_dirs(paths) do
    paths
    |> Enum.sort(fn preceding, succeeding ->
      String.length(preceding) >= String.length(succeeding)
    end)
    |> Enum.map(fn path -> File.rmdir(path) end)
    |> Xit.MiscUtil.traverse_simple()
  end

  @spec write_files([String.t()], Xit.IndexMeta.file_meta()) :: :ok | {:error, any}
  defp write_files(paths, file_meta) do
    paths
    |> Xit.MiscUtil.map_p(fn path ->
      if Map.has_key?(file_meta, path) do
        id = Map.get(file_meta, path)
        write_blob_to_path(id, path)
      else
        {:error, :file_meta_corrupted}
      end
    end)
    |> Xit.MiscUtil.traverse_simple()
  end

  @spec write_blob_to_path(String.t(), String.t()) :: :ok | {:error, any}
  defp write_blob_to_path(blob_id, path) do
    with {:ok, blob} <- Xit.ObjectRepo.read(blob_id) do
      case blob do
        %Xit.Blob{} ->
          with :ok <- File.mkdir_p(Path.dirname(path)),
               :ok <- File.write(path, blob.content) do
            :ok
          else
            error -> error
          end

        _ ->
          {:error, :object_corrupted}
      end
    end
  end
end
