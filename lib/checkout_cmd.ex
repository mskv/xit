defmodule Xit.CheckoutCmd do
  @spec call(String.t()) :: :ok | {:error, any}
  def call(id) do
    with {:ok, commit} <- Xit.ObjectRepo.read(id),
         :ok <- Xit.MiscUtil.ok_or(is_commit(commit), :not_commit),
         {:ok, index} <- Xit.ReadTreeToIndex.call(Xit.Index.new(), commit.tree),
         :ok <- Xit.Index.write(index),
         :ok <- Xit.CheckoutIndex.call(index) do
      :ok
    else
      error -> error
    end
  end

  @spec is_commit(Xit.ObjectRepo.object()) :: boolean
  defp is_commit(object) do
    case object do
      %Xit.Commit{} -> true
      _ -> false
    end
  end
end
