defmodule Xit.Cmd.Commit do
  @doc """
  Committing consists of the following... we first build a tree from the
  current staging area (index). Then we find out what the current HEAD is
  pointing to. We build a commit pointing at the constructed tree and
  treating the current HEAD as its primary parent. We then persist the
  constructed commit. Finally, we update the HEAD to point at the new commit.
  """
  @spec call() :: :ok | {:error, any}
  def call do
    with {:ok, index} <- Xit.Index.read(),
         {:ok, tree_sha} <- Xit.WriteTreeFromIndex.call(index),
         {:ok, head} <- Xit.Head.read(),
         parent_ids <- if(String.length(head) > 0, do: [head], else: []),
         {:ok, commit_sha} <- Xit.Commit.new(tree_sha, parent_ids) |> Xit.ObjectRepo.write(),
         :ok <- Xit.Head.write(commit_sha) do
      :ok
    end
  end
end
