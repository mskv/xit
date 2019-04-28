defmodule Xit.MiscUtil do
  @type result(ok, error) :: {:ok, ok} | {:error, error}
  @type simple_result(error) :: :ok | {:error, error}

  @doc """
  Turns a list of results into a result of list of values.
  In case of an error, returns the first one encountered.

  ## Examples

      iex> Xit.MiscUtil.traverse([])
      {:ok, []}

      iex> Xit.MiscUtil.traverse([{:ok, 1}, {:ok, 2}, {:ok, 3}])
      {:ok, [1, 2, 3]}

      iex> Xit.MiscUtil.traverse([{:ok, 1}, {:error, :reason1}, {:error, :reason2}])
      {:error, :reason1}
  """
  @spec traverse([result(ok, error)]) :: result([ok], error) when ok: var, error: var
  def traverse(results) do
    List.foldr(
      results,
      {:ok, []},
      fn result, acc ->
        with {:ok, value} <- result,
             {:ok, values} <- acc do
          {:ok, [value | values]}
        else
          error -> error
        end
      end
    )
  end

  @doc """
  Turns a list of simple results into a single simple result.
  In case of an error, returns the first one encountered.

  ## Examples

      iex> Xit.MiscUtil.traverse_simple([])
      :ok

      iex> Xit.MiscUtil.traverse_simple([:ok, :ok, :ok])
      :ok

      iex> Xit.MiscUtil.traverse_simple([:ok, {:error, :reason1}, {:error, :reason2}])
      {:error, :reason1}
  """
  @spec traverse_simple([simple_result(error)]) :: simple_result(error) when error: var
  def traverse_simple(results) do
    List.foldr(
      results,
      :ok,
      fn result, acc ->
        with :ok <- result,
             :ok <- acc do
          :ok
        else
          error -> error
        end
      end
    )
  end

  @doc """
  Turns a boolean value into :ok or {:error, reason}.

  ## Examples

      iex> Xit.MiscUtil.ok_or(true, :reason)
      :ok

      iex> Xit.MiscUtil.ok_or(false, :reason)
      {:error, :reason}
  """
  @spec ok_or(boolean, reason) :: :ok | {:error, reason} when reason: var
  def ok_or(boolean, reason), do: if(boolean, do: :ok, else: {:error, reason})

  @doc """
  Maps over a collection concurrently.
  """
  @spec map_p([a], (a -> b)) :: [b] when a: var, b: var
  def map_p(items, fun) do
    # TODO: allow batching
    items
    |> Enum.map(fn item -> Task.async(fn -> fun.(item) end) end)
    |> Enum.map(&Task.await/1)
  end

  @doc """
  Maps over a collection concurrently using `map_p/2`,
  and then gathers the results with `traverse/1`.
  """
  @spec map_traverse_p([a], (a -> result(b, error))) :: result([b], error) when a: var, b: var, error: var
  def map_traverse_p(items, fun) do
    items |> map_p(fun) |> traverse()
  end
end
