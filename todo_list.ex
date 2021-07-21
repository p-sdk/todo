defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      fn entry, todo_list_acc ->
        add_entry(todo_list_acc, entry)
      end
    )
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)
    new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)

    %TodoList{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        old_entry_id = old_entry.id
        new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    %TodoList{todo_list | entries: Map.delete(todo_list.entries, entry_id)}
  end
end

defmodule TodoList.CsvImporter do
  def import(filename) do
    filename
    |> read_lines()
    |> build_entries()
    |> TodoList.new()
  end

  defp read_lines(filename) do
    filename
    |> File.stream!()
    |> Stream.map(&String.replace(&1, "\n", ""))
  end

  defp build_entries(lines) do
    lines
    |> Stream.map(&parse_line/1)
    |> Stream.map(&build_entry/1)
  end

  defp parse_line(line) do
    [date_str, title] = String.split(line, ",")

    {parse_date(date_str), title}
  end

  defp parse_date(date_str) do
    [year, month, day] =
      date_str
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    Date.new!(year, month, day)
  end

  defp build_entry({date, title}) do
    %{date: date, title: title}
  end
end

ExUnit.start()

defmodule TodoListTest do
  use ExUnit.Case, async: true

  test "TodoList CRUD" do
    todo_list =
      TodoList.new()
      |> TodoList.add_entry(%{date: ~D[2018-12-19], title: "Dentist"})
      |> TodoList.add_entry(%{date: ~D[2018-12-20], title: "Shopping"})
      |> TodoList.add_entry(%{date: ~D[2018-12-19], title: "Movies"})

    assert [%{date: ~D[2018-12-19], title: "Dentist"}, %{date: ~D[2018-12-19], title: "Movies"}] =
             TodoList.entries(todo_list, ~D[2018-12-19])

    assert [] == TodoList.entries(todo_list, ~D[2018-12-18])

    assert [%{date: ~D[2018-12-21], title: "Dentist"}] =
             todo_list
             |> TodoList.update_entry(1, fn entry -> %{entry | date: ~D[2018-12-21]} end)
             |> TodoList.entries(~D[2018-12-21])

    assert [] ==
             todo_list
             |> TodoList.delete_entry(2)
             |> TodoList.entries(~D[2018-12-20])
  end

  test "builds TodoList iteratively" do
    entries = [
      %{date: ~D[2018-12-19], title: "Dentist"},
      %{date: ~D[2018-12-20], title: "Shopping"},
      %{date: ~D[2018-12-19], title: "Movies"}
    ]

    todo_list = TodoList.new(entries)

    assert [%{date: ~D[2018-12-20], id: 2, title: "Shopping"}] ==
             TodoList.entries(todo_list, ~D[2018-12-20])
  end

  test "CSV importer" do
    todo_list = TodoList.CsvImporter.import("todos.csv")

    assert [%{date: ~D[2018-12-20], id: 2, title: "Shopping"}] ==
             TodoList.entries(todo_list, ~D[2018-12-20])
  end
end
