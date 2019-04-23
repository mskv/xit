defmodule Xit.ObjectRepo do
  @type object :: Xit.Blob.t() | Xit.Tree.t()

  @spec persist_blobs_by_paths([String.t()]) :: {:ok, [String.t()]} | {:error, any}
  def persist_blobs_by_paths(paths) do
    # TODO: batch to keep memory usage in check
    paths
    |> Enum.map(fn path -> Task.async(fn -> persist_blob_by_path(path) end) end)
    |> Enum.map(&Task.await/1)
    |> List.foldr({:ok, []}, fn result, acc ->
      with {:ok, shas} <- acc,
           {:ok, sha} <- result do
        {:ok, [sha | shas]}
      else
        error -> error
      end
    end)
  end

  @spec persist_blob_by_path(String.t()) :: {:ok, String.t()} | {:error, any}
  def persist_blob_by_path(path) do
    with :ok <- ensure_file(path),
         {:ok, content} <- File.read(path) do
      persist_object(%Xit.Blob{content: content})
    else
      error -> error
    end
  end

  @spec persist_object(object) :: {:ok, String.t()} | {:error, any}
  def persist_object(object) do
    serialized = :erlang.term_to_binary(object)
    sha = :crypto.hash(:sha, serialized) |> Base.encode16()
    file_path = Path.join(Xit.Constants.objects_dir_path(), sha)

    if File.exists?(file_path) do
      {:ok, sha}
    else
      case File.write(file_path, serialized) do
        :ok -> {:ok, sha}
        error -> error
      end
    end
  end

  @spec ensure_file(String.t()) :: :ok | {:error, :not_file}
  defp ensure_file(path) do
    if File.exists?(path) && !File.dir?(path), do: :ok, else: {:error, :not_file}
  end
end
