defmodule Xit.Head do
  @spec read() :: {:ok, String.t()} | {:error, any}
  def read() do
    File.read(Xit.Constants.head_path())
  end

  @spec read!() :: String.t()
  def read!() do
    File.read!(Xit.Constants.head_path())
  end

  @spec write(String.t()) :: :ok | {:error, any}
  def write(sha) do
    File.write(Xit.Constants.head_path(), sha)
  end

  @spec write!(String.t()) :: :ok
  def write!(sha) do
    File.write!(Xit.Constants.head_path(), sha)
  end
end
