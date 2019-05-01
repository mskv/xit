defmodule Xit.Cmd.Init do
  @doc """
  Creates the `.xit` directory. Inside it there is a "HEAD" file, "index" file
  and an empty "object" directory.
  """
  @spec call() :: {:ok, :initialized} | {:ok, :reinitialized} | {:error, any}
  def call do
    ok_status = if db_base_dir_exists(), do: :reinitialized, else: :initialized

    case populate_base_directory() do
      :ok -> {:ok, ok_status}
      error -> error
    end
  end

  @spec db_base_dir_exists() :: boolean
  defp db_base_dir_exists() do
    File.exists?(Xit.Constants.base_dir_path())
  end

  @spec populate_base_directory() :: :ok | {:error, any}
  defp populate_base_directory() do
    File.mkdir_p(Xit.Constants.objects_dir_path())
    File.touch(Xit.Constants.index_path())
    File.touch(Xit.Constants.head_path())
  end
end
