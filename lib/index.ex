defmodule Xit.Index do
  defmodule Entry do
    @enforce_keys [:path, :id]
    defstruct [:path, :id]

    @type t :: %__MODULE__{
            path: String.t(),
            id: String.t()
          }
  end

  @enforce_keys [:entries]
  defstruct [:entries]

  @type t :: %__MODULE__{
          entries: list(Entry.t())
        }

  @spec new() :: t()
  def new() do
    %__MODULE__{entries: []}
  end

  @spec update(String.t(), [Entry.t()]) :: :ok | {:error, any}
  def update(path, desired_entries) do
    with {:ok, index} <- read(),
         {:ok, updated_index} <- do_update(index, path, desired_entries),
         :ok <- write(updated_index) do
      :ok
    else
      error -> error
    end
  end

  @spec read() :: {:ok, __MODULE__.t()} | {:error, any}
  def read() do
    with {:ok, serialized} <- File.read(Xit.Constants.index_path()) do
      # :erlang.binary_to_term assumes correct input, otherwise throws
      deserialized =
        try do
          case :erlang.binary_to_term(serialized) do
            result = %Xit.Index{} -> result
            _ -> new()
          end
        rescue
          ArgumentError -> new()
        end

      {:ok, deserialized}
    else
      error -> error
    end
  end

  @spec write(__MODULE__.t()) :: :ok | {:error, any}
  def write(index) do
    serialized = :erlang.term_to_binary(index)

    with :ok <- File.write(Xit.Constants.index_path(), serialized) do
      :ok
    else
      error -> error
    end
  end

  @spec(
    do_update(__MODULE__.t(), String.t(), [Entry.t()]) :: {:ok, __MODULE__.t()},
    {:error, any}
  )
  defp do_update(index, path, desired_entries) do
    with {:ok, cwd} <- File.cwd() do
      path_relative = Path.relative_to(path, cwd)

      desired_entries_relative =
        Enum.map(desired_entries, fn entry ->
          %Entry{entry | path: Path.relative_to(entry.path, cwd)}
        end)

      existant_entries_outside_path =
        Enum.filter(index.entries, fn entry ->
          not String.starts_with?(Path.relative_to(entry.path, cwd), path_relative)
        end)

      {:ok,
       %Xit.Index{
         index
         | entries: Enum.concat(desired_entries_relative, existant_entries_outside_path)
       }}
    else
      error -> error
    end
  end
end
