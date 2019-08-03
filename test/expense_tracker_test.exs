defmodule ExpenseTrackerTest do
  use ExUnit.Case
  doctest ExpenseTracker

  test "greets the world" do
    assert ExpenseTracker.hello() == :world
  end
end
