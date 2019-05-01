defmodule Xit.CheckoutIndex do
  @doc """
  The goal is to make the contents of `index` the new working directory.
  To achieve that, we first compute a new Xit.Index for the current
  working directory. Then we compute Xit.IndexMeta for both the desired
  index and the index we had just computed. Xit.IndexMeta is easy to compare,
  and so with it we determine what files/dirs need deleting/adding to achieve
  the goal.
  """
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
      end
    end
  end

  # Builds an index for a list of file paths. To do that, it needs to read
  # all the files and compute their SHAs. Unfortunately, with the way I had
  # implemented my serialization, the files cannot be streamed.
  @spec build_index([String.t()]) :: {:ok, Xit.Index.t()} | {:error, any}
  defp build_index(file_paths) do
    with {:ok, ids} <- Xit.Helpers.map_traverse_parallel(file_paths, &get_file_blob_id/1) do
      index_entries =
        Enum.zip(file_paths, ids)
        |> Enum.map(fn {path, id} -> %Xit.Index.Entry{path: path, id: id} end)

      {:ok, %Xit.Index{entries: index_entries}}
    end
  end

  # Puts the file contents into an Xit.Blob and computes SHA for it.
  @spec get_file_blob_id(String.t()) :: {:ok, String.t()} | {:error, any}
  defp get_file_blob_id(file_path) do
    with {:ok, content} <- File.read(file_path) do
      {:ok, Xit.Blob.new(content) |> Xit.ObjectRepo.serialize_and_get_id() |> elem(0)}
    end
  end

  # Deletes files identified by give paths.
  @spec delete_files([String.t()]) :: :ok | {:error, any}
  defp delete_files(paths) do
    paths
    |> Xit.Helpers.map_parallel(&File.rm/1)
    |> Xit.Helpers.traverse_simple()
  end

  # Deletes dirs identified by given `paths`. It will fail if the dir is not
  # empty, so you need to make sure all the files are gone already.
  # It does not happen concurrently for the following reason... when calling
  # this function I sometimes pass values like "test/something" and "test".
  # To ensure that "test/something" gets deleted before "test", I first sort
  # all the paths. Could probably be done smarter and concurrently with more
  # work done on the paths before passing them here.
  @spec delete_dirs([String.t()]) :: :ok | {:error, any}
  defp delete_dirs(paths) do
    paths
    |> Enum.sort(fn preceding, succeeding ->
      String.length(preceding) >= String.length(succeeding)
    end)
    |> Enum.map(fn path -> File.rmdir(path) end)
    |> Xit.Helpers.traverse_simple()
  end

  # Writes `paths` to the working directory. The contents of the files pointed
  # to by the `paths` are determined thanks to the `file_meta`. Again, no
  # file streaming due to how I implemented object serialization.
  @spec write_files([String.t()], Xit.IndexMeta.file_meta()) :: :ok | {:error, any}
  defp write_files(paths, file_meta) do
    paths
    |> Xit.Helpers.map_parallel(fn path ->
      if Map.has_key?(file_meta, path) do
        id = Map.get(file_meta, path)
        write_blob_to_path(id, path)
      else
        {:error, :file_meta_corrupted}
      end
    end)
    |> Xit.Helpers.traverse_simple()
  end

  # Writes a single blob identified by `blob_id` to the given `path`.
  @spec write_blob_to_path(String.t(), String.t()) :: :ok | {:error, any}
  defp write_blob_to_path(blob_id, path) do
    with {:ok, blob} <- Xit.ObjectRepo.read(blob_id) do
      case blob do
        %Xit.Blob{} ->
          with :ok <- File.mkdir_p(Path.dirname(path)),
               :ok <- File.write(path, blob.content) do
            :ok
          end

        _ ->
          {:error, :object_corrupted}
      end
    end
  end
end
