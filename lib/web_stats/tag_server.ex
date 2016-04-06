defmodule WebStats.TagServer do
  def start_link(url \\ __MODULE__) do
    Agent.start_link(fn -> %{} end, name: url)
  end

  def put_tags(url, tags) do
    Agent.update url, fn map ->
      Map.merge map, tags, fn _tag, m, t ->
        m + t
      end
    end

    Agent.update __MODULE__, fn map ->
      Map.merge map, tags, fn _tag, m, t ->
        m + t
      end
    end
  end

  def pretty_print(url \\ __MODULE__) do
    Agent.get url, fn map ->
      IO.inspect(map, limit: :infinity)
    end
  end

  def clear_state(url \\ __MODULE__) do
    Agent.update url, fn _map -> %{} end
  end
end
