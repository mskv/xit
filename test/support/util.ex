defmodule Support.Util do
  def lists_eq_irrespective_of_order(first, second) do
    first -- second === second -- first
  end
end
