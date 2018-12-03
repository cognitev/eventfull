defmodule EventfulWeb.Api.EventController do
  use EventfulWeb, :controller

  require Poison

  alias Eventful.Resources
  alias Eventful.Resources.Event

  action_fallback EventfulWeb.FallbackController

  def index(conn, _params) do
    events = Resources.list_events()
    render(conn, "index.json", events: events)
  end

  def create(conn, %{"event" => event_params}) do
    event_params = %{event_params | "payload" => Poison.encode!(event_params["payload"])}

    with {:ok, %Event{} = event} <- Resources.create_event(event_params) do
      Eventful.Notifier.fanout(event)

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_event_path(conn, :show, event))
      |> render("show.json", event: event)
    end
  end

  def show(conn, %{"id" => id}) do
    event = Resources.get_event!(id)
    render(conn, "show.json", event: event)
  end
end
