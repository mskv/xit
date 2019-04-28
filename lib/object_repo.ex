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
    {id, serialized} = serialize_and_get_id(object)

    case maybe_write_file(id, serialized) do
      :ok -> {:ok, id}
      error -> error
    end
  end

  @spec write!(object) :: String.t()
  def write!(object) do
    case write(object) do
      {:ok, id} -> id
      _ -> raise "object writing failed"
    end
  end

  @spec serialize_and_get_id(object) :: {String.t(), String.t()}
  def serialize_and_get_id(object) do
    # Bad choice of serialization. It won't allow to stream id generation.
    # A solution would be to separate blob content and header.
    # Then we could update the hash with the header separately and the content
    # could be streamed from the disk. Right now we have to load the whole thing
    # into memory as the content is entwined with the header.
    # By "header" I mean the metadata contained in the struct, for instance the
    # very fact that an object is a %Xit.Blob{}. As described above, this bit
    # could be separated from file content to allow streaming the content.
    serialized = :erlang.term_to_binary(object)
    id = :crypto.hash(:sha, serialized) |> Base.encode16()
    {id, serialized}
  end

  @spec maybe_write_file(String.t(), String.t()) :: :ok | {:error, any}
  def maybe_write_file(id, content) do
    file_path = object_file_path(id)

    if File.exists?(file_path) do
      :ok
    else
      File.write(file_path, content)
    end
  end

  @spec object_file_path(String.t()) :: String.t()
  defp object_file_path(object_id) do
    Path.join(Xit.Constants.objects_dir_path(), object_id)
  end
end
