defmodule WebStats.UrlServer do
  def start_link do
    Agent.start(fn -> MapSet.new end, name: __MODULE__)
  end

  def has_page?(url) do
    Agent.get __MODULE__, fn set ->
      MapSet.member?(set, url)
    end
  end

  def page_count do
    Agent.get __MODULE__, fn set ->
      MapSet.size(set)
    end
  end

  def put_page(url) do
    Agent.update __MODULE__, fn set ->
      MapSet.put(set, url)
    end
  end

  def get_pages do
    Agent.get __MODULE__, fn set -> set end
  end

  def print_pages do
    Agent.get __MODULE__, fn set ->
      IO.inspect(set, limit: :infinity)
    end
  end

  def clear_state do
    Agent.update __MODULE__, fn _set ->
      MapSet.new
    end
  end
end
