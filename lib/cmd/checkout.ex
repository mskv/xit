defmodule Xit.Cmd.Checkout do
  @doc """
  The goal is to set the contents of the working directory to the contents
  of the tree pointed to by the commit identified by `id`. To do that, we
  first read the commit tree into the staging area (index) and then
  write the staging area to the working directory.
  """
  @spec call(String.t()) :: :ok | {:error, any}
  def call(id) do
    with {:ok, commit} <- Xit.ObjectRepo.read(id),
         :ok <- Xit.MiscUtil.ok_or(is_commit(commit), :not_commit),
         {:ok, index} <- Xit.ReadTreeToIndex.call(Xit.Index.new(), commit.tree),
         :ok <- Xit.Index.write(index),
         :ok <- Xit.CheckoutIndex.call(index) do
      :ok
    end
  end

  # Checks whether an Xit.ObjectRepo.object is an Xit.Commit, should probably
  # be extracted somewhere once it's needed elsewhere.
  @spec is_commit(Xit.ObjectRepo.object()) :: boolean
  defp is_commit(object) do
    case object do
      %Xit.Commit{} -> true
      _ -> false
    end
  end
end
