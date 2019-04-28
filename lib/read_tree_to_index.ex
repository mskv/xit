defmodule Xit.ReadTreeToIndex do
  @doc """
  The goal is to construct an index based on the given initial `index`
  and the contents of the tree identified by `tree_id` loaded into this
  `index`, prefixed by `prefix`.
  In practice, `prefix` is almost always the home directory. An exception
  would be the `--prefix` flag in Git, but we don't use it for now anywhere
  in Xit. We walk the given tree recursively, updating the index level by level.
  """
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

  # Returns a tree identified by the given `tree_id`. Should probably
  # be extracted if it's ever needed elsewhere, as it does not belong here.
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

  # Tree edges either point at blobs or another trees. Currently we don't
  # have data redundancy on the tree level. The information whether an object
  # is a tree or a blob is stored withing the object itself. So we
  # first needs to load the objects into memory to find out what they are.
  # Then we can partition them into two cathegories. As always, my backwards
  # serialization strategy prevents me from doing any optimization in terms
  # of reading just the file headers. Ideally, I should be able to read just
  # a few bytes of files to find out what type of files they are. Here, I need
  # to read the whole thing to know whether it's a tree or a blob.
  @spec partition_tree_edges(Xit.Tree.t()) :: {:ok, {[Xit.Tree.Edge.t()], [Xit.Tree.Edge.t()]}} | {:error, any}
  defp partition_tree_edges(tree) do
    tree.edges
    |> Xit.MiscUtil.map_p(fn edge -> Xit.ObjectRepo.read(edge.id) end)
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
