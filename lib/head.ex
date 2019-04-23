defmodule Xit.Head do
  @spec get() :: {:ok, String.t()} | {:error, any}
  def get() do
    File.read(Xit.Constants.head_path())
  end

  @spec set(String.t()) :: :ok | {:error, any}
  def set(sha) do
    File.write(Xit.Constants.head_path(), sha)
  end
end
