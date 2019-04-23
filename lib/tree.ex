defmodule Xit.Tree do
  defmodule Edge do
    @enforce_keys [:path, :id]
    defstruct [:path, :id]

    @type t :: %__MODULE__{
            path: String.t(),
            id: String.t()
          }
  end

  @enforce_keys [:edges]
  defstruct [:edges]

  @type t :: %__MODULE__{
          edges: list(Edge.t())
        }
end
