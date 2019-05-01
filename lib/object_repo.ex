defmodule Xit.ObjectRepo do
  @type object :: Xit.Blob.t() | Xit.Tree.t() | Xit.Commit.t()

  @spec read(String.t()) :: {:ok, object} | {:error, any}
  def read(object_id) do
    with file_path <- object_file_path(object_id),
         {:ok, serialized} <- File.read(file_path) do
      {:ok, Xit.Serializer.deserialize(serialized, {:error, :corrupted_object})}
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

    case maybe_write_file({id, serialized}) do
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
    serialized = Xit.Serializer.serialize(object)
    id = :crypto.hash(:sha, serialized) |> Base.encode16()
    {id, serialized}
  end

  @spec maybe_write_file({String.t(), String.t()}) :: :ok | {:error, any}
  defp maybe_write_file({id, content}) do
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
