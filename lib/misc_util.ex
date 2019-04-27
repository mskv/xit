defmodule Xit.MiscUtil do
  @type result(ok, error) :: {:ok, ok} | {:error, error}

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
  Turns a boolean value into :ok or {:error, reason}.

  ## Examples

      iex> Xit.MiscUtil.ok_or(true, :reason)
      :ok

      iex> Xit.MiscUtil.ok_or(false, :reason)
      {:error, :reason}
  """
  @spec ok_or(boolean, reason) :: :ok | {:error, reason} when reason: var
  def ok_or(boolean, reason), do: if(boolean, do: :ok, else: {:error, reason})
end
