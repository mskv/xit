defmodule Xit.ReadTreeToIndex do
  @spec call(Xit.Index.t(), String.t(), String.t()) :: {:ok, Xit.Index.t()} | {:error, any}
  def call(index, tree_id, prefix \\ "") do
    with {:ok, tree} <- read_tree(tree_id),
         {:ok, {tree_edges, blob_edges}} <- partition_tree_edges(tree) do
      desired_index_entries =
        Enum.map(blob_edges, fn edge ->
          path = Path.join(prefix, edge.path)
          id = edge.id
          %Xit.Index.Entry{path: path, id: id}
        end)

      updated_index = Xit.Index.update_deep(index, prefix, desired_index_entries)

      Enum.reduce(
        tree_edges,
        {:ok, updated_index},
        fn edge, acc ->
          with {:ok, index} <- acc do
            call(index, edge.id, Path.join(prefix, edge.path))
          else
            error -> error
          end
        end
      )
    else
      error -> error
    end
  end

  @spec read_tree(String.t()) :: {:ok, Xit.Tree.t()} | {:error, any}
  defp read_tree(tree_id) do
    with {:ok, object} <- Xit.ObjectRepo.read(tree_id) do
      case object do
        %Xit.Tree{} -> {:ok, object}
        _ -> {:error, :invalid_object}
      end
    else
      error -> error
    end
  end

  @spec partition_tree_edges(Xit.Tree.t()) :: {:ok, {[Xit.Tree.Edge.t()], [Xit.Tree.Edge.t()]}} | {:error, any}
  defp partition_tree_edges(tree) do
    tree.edges
    |> Enum.map(fn edge -> Task.async(fn -> Xit.ObjectRepo.read(edge.id) end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.zip(tree.edges)
    |> Enum.reduce(
      {:ok, {[], []}},
      fn {result, edge}, acc ->
        with {:ok, {tree_edges, blob_edges}} <- acc,
             {:ok, object} <- result do
          case object do
            %Xit.Tree{} -> {:ok, {[edge | tree_edges], blob_edges}}
            %Xit.Blob{} -> {:ok, {tree_edges, [edge | blob_edges]}}
            _ -> {:error, :invalid_object}
          end
        else
          error -> error
        end
      end
    )
  end
end
