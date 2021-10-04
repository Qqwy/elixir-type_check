defmodule DependingProjectTest do
  use ExUnit.Case
  doctest DependingProject

  test "greets the world" do
    assert DependingProject.hello() == :world
  end
end
