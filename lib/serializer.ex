defmodule Xit.Serializer do
  @spec serialize(any) :: String.t()
  def serialize(term) do
    # Bad choice of serialization. It won't allow to stream id generation.
    # A solution would be to separate object content and header.
    # Then we could update the hash with the header separately and the content
    # could be streamed from the disk. Right now we have to load the whole thing
    # into memory as the content is entwined with the header.
    # By "header" I mean the metadata contained in the struct, for instance the
    # very fact that an object is a %Xit.Blob{}. As described above, this bit
    # could be separated from file content to allow streaming the content.
    :erlang.term_to_binary(term)
  end

  @spec deserialize(String.t(), any) :: any
  def deserialize(binary, fallback) do
    # :erlang.binary_to_term assumes correct input, otherwise throws
    try do
      :erlang.binary_to_term(binary)
    rescue
      ArgumentError -> fallback
    end
  end
end
