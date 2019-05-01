defmodule Xit.Helpers do
  @type result(ok, error) :: {:ok, ok} | {:error, error}
  @type simple_result(error) :: :ok | {:error, error}

  @doc """
  Turns a list of results into a result of list of values.
  In case of an error, returns the first one encountered.

  ## Examples

      iex> Xit.Helpers.traverse([])
      {:ok, []}

      iex> Xit.Helpers.traverse([{:ok, 1}, {:ok, 2}, {:ok, 3}])
      {:ok, [1, 2, 3]}

      iex> Xit.Helpers.traverse([{:ok, 1}, {:error, :reason1}, {:error, :reason2}])
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
        end
      end
    )
  end

  @doc """
  Turns a list of simple results into a single simple result.
  In case of an error, returns the first one encountered.

  ## Examples

      iex> Xit.Helpers.traverse_simple([])
      :ok

      iex> Xit.Helpers.traverse_simple([:ok, :ok, :ok])
      :ok

      iex> Xit.Helpers.traverse_simple([:ok, {:error, :reason1}, {:error, :reason2}])
      {:error, :reason1}
  """
  @spec traverse_simple([simple_result(error)]) :: simple_result(error) when error: var
  def traverse_simple(results) do
    Enum.reduce(
      results,
      :ok,
      fn result, acc ->
        with :ok <- acc, do: result
      end
    )
  end

  @doc """
  Turns a boolean value into :ok or {:error, reason}.

  ## Examples

      iex> Xit.Helpers.ok_or(true, :reason)
      :ok

      iex> Xit.Helpers.ok_or(false, :reason)
      {:error, :reason}
  """
  @spec ok_or(boolean, reason) :: :ok | {:error, reason} when reason: var
  def ok_or(true, _reason), do: :ok
  def ok_or(false, reason), do: {:error, reason}

  @doc """
  Maps over a collection concurrently.
  """
  @spec map_parallel([a], (a -> b)) :: [b] when a: var, b: var
  def map_parallel(items, fun) do
    # TODO: allow batching
    items
    |> Enum.map(fn item -> Task.async(fn -> fun.(item) end) end)
    |> Enum.map(&Task.await/1)
  end

  @doc """
  Maps over a collection concurrently using `map_parallel/2`,
  and then gathers the results with `traverse/1`.
  """
  @spec map_traverse_parallel([a], (a -> result(b, error))) :: result([b], error) when a: var, b: var, error: var
  def map_traverse_parallel(items, fun) do
    items |> map_parallel(fun) |> traverse()
  end
end
