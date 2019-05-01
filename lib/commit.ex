defmodule Xit.Commit do
  @enforce_keys [:tree, :parents]
  defstruct [:tree, :parents]

  @type t :: %__MODULE__{
          tree: String.t(),
          parents: [String.t()]
        }

  @doc """
  Commit without a parent is a root commit.
  """
  @spec root?(__MODULE__.t()) :: boolean
  def root?(%__MODULE__{parents: []}), do: true
  def root?(_), do: false

  @doc """
  The data model supports multiple commit parents. However, our implementation
  for now has no chance of that happening. A merge commit in Git has
  multiple parents, but Xit cannot merge yet... Anyway, the primary parent
  (shown in `xit log` command) is always the first parent.
  """
  @spec primary_parent_id(__MODULE__.t()) :: String.t() | nil
  def primary_parent_id(commit) do
    List.first(commit.parents)
  end

  @spec new(String.t(), [String.t()]) :: __MODULE__.t()
  def new(tree_id, parent_ids) do
    %__MODULE__{tree: tree_id, parents: parent_ids}
  end
end
