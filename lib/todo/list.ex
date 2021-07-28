defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %Todo.List{},
      fn entry, todo_list_acc ->
        add_entry(todo_list_acc, entry)
      end
    )
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)
    new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)

    %Todo.List{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
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
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    %Todo.List{todo_list | entries: Map.delete(todo_list.entries, entry_id)}
  end
end

defimpl Collectable, for: Todo.List do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}),
    do: Todo.List.add_entry(todo_list, entry)

  defp into_callback(todo_list, :done),
    do: todo_list

  defp into_callback(_todo_list, :halt),
    do: :ok
end

defmodule Todo.List.CsvImporter do
  def import(filename) do
    filename
    |> read_lines()
    |> build_entries()
    |> Todo.List.new()
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
