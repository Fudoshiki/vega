defmodule VegaWeb.BoardLive do
  use Phoenix.LiveView

  alias Vega.Board
  alias Vega.User
  alias Vega.Issue
  alias Phoenix.LiveView.Socket

  def mount(_params, session, socket) do
    current_user = User.fetch()

    board = case Board.fetch_one() do
      nil -> create_example_board(current_user)
      other -> other
    end

    current_user = User.fetch()
    history = Issue.fetch_all(board)
    {:ok, assign(socket, board: board, current_user: current_user, edit: false, history: history)}
  end

  def handle_info({:updated_board, board}, socket) do
    {:noreply, assign(socket, board: board, history: Issue.fetch_all(board))}
  end

  def handle_event("new", _value, %Socket{assigns: assigns} = socket) do

    with {:ok, _, _} <- Board.delete(assigns.board) do

      board = create_example_board(assigns.current_user)
      {:noreply, assign(socket, board: board, history: Issue.fetch_all(board))}
    end
  end

  defp create_example_board(user) do
    title = "A board title"
    board = Board.new(title, user)

    board = Board.add_list(board, user, "to do")
    board = Board.add_list(board, user, "doing")
    board = Board.add_list(board, user, "done")
  end
  def handle_event("edit", _value, socket) do
    {:noreply, assign(socket, :edit, true)}
  end

  def handle_event("save", %{"board" => %{"title" => new_title}}, %Socket{assigns: %{board: board}} = socket) do
    board = save_title(new_title, board)
    history = Issue.fetch_all(board)
    {:noreply, assign(socket, board: board, edit: false, history: history)}
  end
  def handle_event("save", %{"type" => "blur", "value" => new_title}, %Socket{assigns: %{board: board}} = socket) do
    board = save_title(new_title, board)
    {:noreply, assign(socket, board: board, edit: false, history: Issue.fetch_all(board))}
  end
  def handle_event("reorder-lists", [], socket) do
    {:noreply, socket}
  end
  def handle_event("reorder-lists", ordering, %Socket{assigns: %{board: board, current_user: current_user}} = socket) when is_list(ordering) do
    lists    = Enum.reduce(board.lists, %{}, fn list, map -> Map.put(map, BSON.ObjectId.encode!(list._id), list) end)
    ordering = Enum.map(ordering, fn list_id -> lists[list_id] end)
    case map_size(lists) == length(ordering) do
      true ->
        board = Board.reorder_list(board, current_user, ordering)
        {:noreply, assign(socket, board: board, history: Issue.fetch_all(board))}
      false ->
        {:noreply, socket}
    end
  end
  def handle_event("reorder-lists", _other, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    Phoenix.View.render(VegaWeb.PageView, "board.html", assigns)
  end

  defp save_title("", board) do
    board
  end
  defp save_title(title, board) do
    case title == board.title do
      true  -> board
      false -> Board.set_title(board, User.fetch(), title)
    end
  end

end