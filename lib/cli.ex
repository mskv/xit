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

  @not_recognized_copy ~S"""
    Not recognized, try 'xit help' to see your options.
  """

  def main(args) do
    case args do
      ["help"] ->
        IO.puts(@help_copy)

      ["init"] ->
        case Xit.Init.call() do
          {:ok, :initialized} -> IO.puts(@initialized_copy)
          {:ok, :reinitialized} -> IO.puts(@reinitialized_copy)
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
end
