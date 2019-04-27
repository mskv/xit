defmodule Xit.Commit do
  @enforce_keys [:tree, :parents]
  defstruct [:tree, :parents]

  @type t :: %__MODULE__{
          tree: String.t(),
          parents: [String.t()]
        }

  @spec is_root?(__MODULE__.t()) :: boolean
  def is_root?(commit) do
    length(commit.parents) === 0
  end

  @spec primary_parent_id(__MODULE__.t()) :: String.t() | nil
  def primary_parent_id(commit) do
    case commit.parents do
      [] -> nil
      [head | _] -> head
    end
  end

  @spec new(String.t(), [String.t()]) :: __MODULE__.t()
  def new(tree_id, parent_ids) do
    %__MODULE__{tree: tree_id, parents: parent_ids}
  end

  @spec persist(__MODULE__.t()) :: {:ok, String.t()} | {:error, any}
  def persist(commit) do
    Xit.ObjectRepo.write(commit)
  end
end
