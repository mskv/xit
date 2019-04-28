defmodule Xit.Blob do
  @enforce_keys [:content]
  defstruct [:content]

  @type t :: %__MODULE__{
          content: String.t()
        }

  def new(content) do
    %__MODULE__{content: content}
  end
end
