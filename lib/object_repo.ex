defmodule Xit.ObjectRepo do
  @type object :: Xit.Blob.t() | Xit.Tree.t() | Xit.Commit.t()

  @spec read(String.t()) :: {:ok, object} | {:error, any}
  def read(object_id) do
    file_path = object_file_path(object_id)

    with {:ok, serialized} <- File.read(file_path) do
      try do
        {:ok, :erlang.binary_to_term(serialized)}
      rescue
        ArgumentError -> {:error, :corrupted_object}
      end
    else
      error -> error
    end
  end

  @spec read!(String.t()) :: object
  def read!(object_id) do
    case read(object_id) do
      {:ok, object} -> object
      _ -> raise "object reading failed"
    end
  end

  @spec write(object) :: {:ok, String.t()} | {:error, any}
  def write(object) do
    serialized = :erlang.term_to_binary(object)
    sha = :crypto.hash(:sha, serialized) |> Base.encode16()
    file_path = object_file_path(sha)

    if File.exists?(file_path) do
      {:ok, sha}
    else
      case File.write(file_path, serialized) do
        :ok -> {:ok, sha}
        error -> error
      end
    end
  end

  @spec write!(object) :: String.t()
  def write!(object) do
    case write(object) do
      {:ok, id} -> id
      _ -> raise "object writing failed"
    end
  end

  @spec write_blobs_by_paths([String.t()]) :: {:ok, [String.t()]} | {:error, any}
  def write_blobs_by_paths(paths) do
    # TODO: batch to keep memory usage in check
    paths
    |> Enum.map(fn path -> Task.async(fn -> write_blob_by_path(path) end) end)
    |> Enum.map(&Task.await/1)
    |> Xit.MiscUtil.traverse()
  end

  @spec write_blob_by_path(String.t()) :: {:ok, String.t()} | {:error, any}
  def write_blob_by_path(path) do
    with :ok <- ensure_file(path),
         {:ok, content} <- File.read(path) do
      write(%Xit.Blob{content: content})
    else
      error -> error
    end
  end

  @spec ensure_file(String.t()) :: :ok | {:error, :not_file}
  defp ensure_file(path) do
    if File.exists?(path) && !File.dir?(path), do: :ok, else: {:error, :not_file}
  end

  @spec object_file_path(String.t()) :: String.t()
  defp object_file_path(object_id) do
    Path.join(Xit.Constants.objects_dir_path(), object_id)
  end
end
