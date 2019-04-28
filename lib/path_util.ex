defmodule Xit.PathUtil do
  @doc """
  Fails on non-existant path.
  Fails on path outside cwd.
  Truncates cwd from the path.
  Normalizes "." to "" for some reason (I don't remember why).

  ## Examples

  Warning: has side effects and weird assumptions.

      iex> Xit.PathUtil.validate_normalize_path("non_existant", File.cwd!())
      {:error, :path_non_existant}

      iex> Xit.PathUtil.validate_normalize_path("..", File.cwd!())
      {:error, :path_outside_cwd}

      iex> Xit.PathUtil.validate_normalize_path("../xit/test", File.cwd!())
      {:ok, "test"}

      iex> Xit.PathUtil.validate_normalize_path("../xit", File.cwd!())
      {:ok, ""}

      iex> Xit.PathUtil.validate_normalize_path(".", File.cwd!())
      {:ok, ""}
  """
  @spec validate_normalize_path(String.t(), String.t()) :: {:ok, String.t()} | {:error, any}
  def validate_normalize_path(path, cwd) do
    expanded = Path.expand(path)

    cond do
      # If expanded equals cwd, it means it points at cwd and we express that as ""
      cwd === expanded -> {:ok, ""}
      # If expanded is a prefix of cwd, it means it's not nested inside cwd
      not File.exists?(expanded) -> {:error, :path_non_existant}
      String.starts_with?(cwd, expanded) -> {:error, :path_outside_cwd}
      true -> {:ok, Path.relative_to(expanded, cwd)}
    end
  end

  @doc """
  Same as Path.dirname, but for now we normalize "." to "". I don't remember why.

  ## Examples

      iex> Xit.PathUtil.dirname("test1/test2")
      "test1"

      iex> Xit.PathUtil.dirname("")
      ""

      iex> Xit.PathUtil.dirname(".")
      ""

      iex> Xit.PathUtil.dirname("./test1")
      ""
  """
  @spec dirname(String.t()) :: String.t()
  def dirname(path) do
    case Path.dirname(path) do
      "." -> ""
      other -> other
    end
  end

  @doc """
  Informs whether the path is prefixed by the repo directory path.

  ## Examples

      iex> Xit.PathUtil.path_prefixed_with_base_dir?("test")
      false

      iex> Xit.PathUtil.path_prefixed_with_base_dir?(".xit/test")
      true
  """
  @spec path_prefixed_with_base_dir?(String.t()) :: boolean
  def path_prefixed_with_base_dir?(path) do
    String.starts_with?(path, Xit.Constants.base_dir_path())
  end

  @doc """
  Informs whether the first path is nested in or equal to the second.

  ## Examples

      iex> Xit.PathUtil.path_nested_in?("", "")
      true

      iex> Xit.PathUtil.path_nested_in?("test", "test")
      true

      iex> Xit.PathUtil.path_nested_in?("", "test")
      false

      iex> Xit.PathUtil.path_nested_in?("test", "")
      true

      iex> Xit.PathUtil.path_nested_in?("test1/test2/test3", "test1/test3")
      false

      iex> Xit.PathUtil.path_nested_in?("test1/test2/test3", "test1/test2")
      true
  """
  @spec path_nested_in?(String.t(), String.t()) :: boolean
  def path_nested_in?(first, second) do
    split_path_nested_in?(Path.split(first), Path.split(second))
  end

  @spec split_path_nested_in?([String.t()], [String.t()]) :: boolean
  defp split_path_nested_in?(_path, []), do: true
  defp split_path_nested_in?([], [_y | _ys]), do: false

  defp split_path_nested_in?([x | xs], [y | ys]) do
    x === y and split_path_nested_in?(xs, ys)
  end

  @doc """
  Returns a list of normalized file paths descended from the given prefix.
  Excludes paths prefixed with base dir.
  """
  @spec normalized_working_dir_paths(String.t(), String.t()) :: {:ok, [String.t()]} | {:error, any}
  def normalized_working_dir_paths(cwd, prefix \\ ".") do
    with {:ok, paths} <-
           Xit.PathUtil.absolute_working_dir_paths(prefix)
           |> Enum.map(&validate_normalize_path(&1, cwd))
           |> Xit.MiscUtil.traverse() do
      {:ok, Enum.reject(paths, &path_prefixed_with_base_dir?/1)}
    else
      error -> error
    end
  end

  @doc """
  Returns a list of absolute file paths descended from the given path.
  If the given path points at a file, returns a one element list containing this path.
  """
  @spec absolute_working_dir_paths(String.t()) :: [String.t()]
  def absolute_working_dir_paths(path) do
    if File.exists?(path) && !File.dir?(path) do
      [Path.expand(path)]
    else
      :filelib.fold_files(
        String.to_charlist(path),
        '.*',
        true,
        fn file, acc -> [to_string(file) | acc] end,
        []
      )
    end
  end
end
