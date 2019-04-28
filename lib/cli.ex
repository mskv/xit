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

  @not_recognized_copy ~S"""
    Not recognized, try 'xit help' to see your options.
  """

  def main(args) do
    case args do
      ["help"] ->
        IO.puts(@help_copy)

      ["init"] ->
        case Xit.InitCmd.call() do
          {:ok, :initialized} -> IO.puts(@initialized_copy)
          {:ok, :reinitialized} -> IO.puts(@reinitialized_copy)
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["add", path] ->
        case Xit.AddCmd.call(path) do
          :ok -> IO.puts(@added_copy)
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["commit"] ->
        case Xit.CommitCmd.call() do
          :ok -> IO.puts(@committed_copy)
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["log"] ->
        case Xit.LogCmd.call() do
          {:ok, log} -> IO.puts(log_copy(log))
          {:error, reason} -> IO.puts(error_copy(reason))
        end

      ["checkout", id] ->
        case Xit.CheckoutCmd.call(id) do
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

  defp log_copy(log) do
    if log === [] do
      "No history"
    else
      Enum.join(log, "\n")
    end
  end

  defp checkout_copy(id) do
    "Currently on #{id}"
  end
end
