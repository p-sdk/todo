defmodule TodoList do
  def new, do: MultiDict.new()

  def add_entry(todo_list, entry) do
    MultiDict.add(todo_list, entry.date, entry)
  end

  def entries(todo_list, date) do
    MultiDict.get(todo_list, date)
  end
end

defmodule MultiDict do
  def new, do: %{}

  def add(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    Map.get(dict, key, [])
  end
end

ExUnit.start()

defmodule TodoListTest do
  use ExUnit.Case, async: true

  test "TodoList" do
    todo_list =
      TodoList.new()
      |> TodoList.add_entry(%{date: ~D[2018-12-19], title: "Dentist"})
      |> TodoList.add_entry(%{date: ~D[2018-12-20], title: "Shopping"})
      |> TodoList.add_entry(%{date: ~D[2018-12-19], title: "Movies"})

    assert [%{date: ~D[2018-12-19], title: "Movies"}, %{date: ~D[2018-12-19], title: "Dentist"}] ==
             TodoList.entries(todo_list, ~D[2018-12-19])

    assert [] == TodoList.entries(todo_list, ~D[2018-12-18])
  end
end
