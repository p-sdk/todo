defmodule Todo.ServerTest do
  use ExUnit.Case, async: true

  test "Todo.Server" do
    Todo.Server.start()

    Todo.Server.add_entry(%{date: ~D[2018-12-19], title: "Dentist"})
    Todo.Server.add_entry(%{date: ~D[2018-12-20], title: "Shopping"})
    Todo.Server.add_entry(%{date: ~D[2018-12-19], title: "Movies"})

    assert [%{date: ~D[2018-12-19], title: "Dentist"}, %{date: ~D[2018-12-19], title: "Movies"}] =
             Todo.Server.entries(~D[2018-12-19])

    assert [] == Todo.Server.entries(~D[2018-12-18])

    Todo.Server.update_entry(1, fn entry -> %{entry | date: ~D[2018-12-21]} end)
    assert [%{date: ~D[2018-12-21], title: "Dentist"}] = Todo.Server.entries(~D[2018-12-21])

    Todo.Server.delete_entry(2)
    assert [] == Todo.Server.entries(~D[2018-12-20])
  end
end
