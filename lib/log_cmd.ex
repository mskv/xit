defmodule Xit.LogCmd do
  @doc """
  Reads the commit pointed at by HEAD. Then it walks the commit ancestry tree
  up, noting all the commit IDs along the way.
  """
  @spec call() :: {:ok, [String.t()]} | {:error, any}
  def call() do
    with {:ok, head} <- Xit.Head.read() do
      if head === "" do
        {:ok, []}
      else
        walk_commit_tree(head)
      end
    end
  end

  @spec walk_commit_tree(String.t()) :: {:ok, [String.t()]} | {:error, any}
  defp walk_commit_tree(commit_id) do
    with {:ok, commit} <- read_commit(commit_id) do
      parent_id = Xit.Commit.primary_parent_id(commit)

      if parent_id do
        with {:ok, ancestry} <- walk_commit_tree(parent_id) do
          {:ok, [commit_id | ancestry]}
        end
      else
        {:ok, [commit_id]}
      end
    end
  end

  @spec read_commit(String.t()) :: {:ok, Xit.Commit.t()} | {:error, any}
  defp read_commit(commit_id) do
    with {:ok, object} <- Xit.ObjectRepo.read(commit_id) do
      case object do
        %Xit.Commit{} -> {:ok, object}
        _ -> {:error, :invalid_object}
      end
    end
  end
end
