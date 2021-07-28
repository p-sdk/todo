defmodule Todo.ListTest do
  use ExUnit.Case, async: true

  test "Todo.List CRUD" do
    todo_list =
      Todo.List.new()
      |> Todo.List.add_entry(%{date: ~D[2018-12-19], title: "Dentist"})
      |> Todo.List.add_entry(%{date: ~D[2018-12-20], title: "Shopping"})
      |> Todo.List.add_entry(%{date: ~D[2018-12-19], title: "Movies"})

    assert [%{date: ~D[2018-12-19], title: "Dentist"}, %{date: ~D[2018-12-19], title: "Movies"}] =
             Todo.List.entries(todo_list, ~D[2018-12-19])

    assert [] == Todo.List.entries(todo_list, ~D[2018-12-18])

    assert [%{date: ~D[2018-12-21], title: "Dentist"}] =
             todo_list
             |> Todo.List.update_entry(1, fn entry -> %{entry | date: ~D[2018-12-21]} end)
             |> Todo.List.entries(~D[2018-12-21])

    assert [] ==
             todo_list
             |> Todo.List.delete_entry(2)
             |> Todo.List.entries(~D[2018-12-20])
  end

  test "builds Todo.List iteratively" do
    entries = [
      %{date: ~D[2018-12-19], title: "Dentist"},
      %{date: ~D[2018-12-20], title: "Shopping"},
      %{date: ~D[2018-12-19], title: "Movies"}
    ]

    todo_list = Todo.List.new(entries)

    assert [%{date: ~D[2018-12-20], id: 2, title: "Shopping"}] ==
             Todo.List.entries(todo_list, ~D[2018-12-20])
  end

  test "implements Collectable for Todo.List" do
    entries = [
      %{date: ~D[2018-12-19], title: "Dentist"},
      %{date: ~D[2018-12-20], title: "Shopping"},
      %{date: ~D[2018-12-19], title: "Movies"}
    ]

    todo_list = for entry <- entries, into: Todo.List.new(), do: entry

    assert [%{date: ~D[2018-12-20], id: 2, title: "Shopping"}] ==
             Todo.List.entries(todo_list, ~D[2018-12-20])
  end

  test "CSV importer" do
    todo_list = Todo.List.CsvImporter.import("test/todos.csv")

    assert [%{date: ~D[2018-12-20], id: 2, title: "Shopping"}] ==
             Todo.List.entries(todo_list, ~D[2018-12-20])
  end
end
