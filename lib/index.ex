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

  @spec new([Entry.t()]) :: t()
  def new(entries \\ []) do
    %__MODULE__{entries: entries}
  end

  @spec read() :: {:ok, __MODULE__.t()} | {:error, any}
  def read() do
    with {:ok, serialized} <- File.read(Xit.Constants.index_path()),
         deserialized <- Xit.Serializer.deserialize(serialized, new()) do
      case deserialized do
        %Xit.Index{} -> {:ok, deserialized}
        _ -> {:ok, new()}
      end
    end
  end

  @spec read!() :: __MODULE__.t()
  def read!() do
    case read() do
      {:ok, index} -> index
      _ -> raise Xit.RuntimeError, "index reading failed"
    end
  end

  @spec write(__MODULE__.t()) :: :ok | {:error, any}
  def write(index) do
    serialized = Xit.Serializer.serialize(index)
    File.write(Xit.Constants.index_path(), serialized)
  end

  @spec write!(__MODULE__.t()) :: :ok
  def write!(index) do
    case write(index) do
      :ok -> :ok
      _ -> raise Xit.RuntimeError, "index writing failed"
    end
  end

  @doc """
  Inside an `index`, there may or may not be entires nested in `dir_path`.
  If an entry is not prefixed by it, it stays untouched.
  If an entry is prefiex by it, it gets deleted/updates/left alone depending
  on whether it matches the contents of `desired_entries`.
  """
  @spec update_deep(__MODULE__.t(), String.t(), [Entry.t()]) :: __MODULE__.t()
  def update_deep(index, dir_path, desired_entries) do
    do_update(index, desired_entries, fn entry ->
      not Xit.PathUtil.path_nested_in?(entry.path, dir_path)
    end)
  end

  @spec update_shallow(__MODULE__.t(), String.t(), [Entry.t()]) :: __MODULE__.t()
  def update_shallow(index, dir_path, desired_entries) do
    do_update(index, desired_entries, fn entry ->
      not (Xit.PathUtil.dirname(entry.path) === dir_path)
    end)
  end

  @spec do_update(
          __MODULE__.t(),
          [Entry.t()],
          (String.t() -> boolean)
        ) :: __MODULE__.t()
  defp do_update(
         index,
         desired_new_entries,
         entry_desirable_fn
       ) do
    desired_existant_entries = Enum.filter(index.entries, entry_desirable_fn)

    new_entries = Enum.concat(desired_new_entries, desired_existant_entries)
    %Xit.Index{index | entries: new_entries}
  end
end
