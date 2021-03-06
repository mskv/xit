defmodule Xit.Cli do
  @help_copy ~S"""
    Sorry, cannot help you now. Try later maybe.
  """

  @initialized_copy ~S"""
    Xit repository initialized.
  """

  @reinitialized_copy ~S"""
    Xit repository reinitialized.
  """

  @added_copy ~S"""
    Changes indexed.
  """

  @committed_copy ~S"""
    Staging area committed.
  """

  @log_no_history_copy ~S"""
    No history.
  """

  @not_recognized_copy ~S"""
    Not recognized, try 'xit help' to see your options.
  """

  def main(args) do
    case args do
      ["help"] ->
        IO.puts(@help_copy)

      ["init"] ->
        case Xit.Cmd.Init.call() do
          {:ok, :initialized} -> IO.puts(@initialized_copy)
          {:ok, :reinitialized} -> IO.puts(@reinitialized_copy)
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["add", path] ->
        case Xit.Cmd.Add.call(path) do
          :ok -> IO.puts(@added_copy)
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["commit"] ->
        case Xit.Cmd.Commit.call() do
          :ok -> IO.puts(@committed_copy)
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["log"] ->
        case Xit.Cmd.Log.call() do
          {:ok, log} -> IO.puts(log_copy(log))
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["checkout", id] ->
        case Xit.Cmd.Checkout.call(id) do
          :ok -> IO.puts(checkout_copy(id))
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      _ ->
        IO.puts(@not_recognized_copy)
    end
  end

  defp error_copy(reason) do
    ~s"""
      An error has occurred...
      #{reason}
    """
  end

  defp log_copy([]), do: @log_no_history_copy
  defp log_copy(log), do: Enum.join(log, "\n")

  defp checkout_copy(id), do: "Currently on #{id}"
end
