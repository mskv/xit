defmodule Xit.Constants do
  @base_dir_path ".xit"
  @objects_dir_path Path.join(@base_dir_path, "objects")
  @head_path Path.join(@base_dir_path, "HEAD")
  @index_path Path.join(@base_dir_path, "index")

  @spec base_dir_path() :: String.t()
  def base_dir_path, do: @base_dir_path

  @spec objects_dir_path() :: String.t()
  def objects_dir_path, do: @objects_dir_path

  @spec head_path() :: String.t()
  def head_path, do: @head_path

  @spec index_path() :: String.t()
  def index_path, do: @index_path
end
