defmodule Xit.CommitCmd do
  @spec call() :: :ok | {:error, any}
  def call do
    with {:ok, index} <- Xit.Index.read(),
         {:ok, tree_sha} <- Xit.WriteTreeFromIndex.call(index),
         {:ok, head} <- Xit.Head.get(),
         parent_ids <- if(String.length(head) > 0, do: [head], else: []),
         {:ok, commit_sha} <- Xit.Commit.new(tree_sha, parent_ids) |> Xit.Commit.persist(),
         :ok <- Xit.Head.set(commit_sha) do
      :ok
    else
      error -> error
    end
  end
end
