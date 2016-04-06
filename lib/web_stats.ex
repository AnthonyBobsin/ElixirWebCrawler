defmodule Assignment3 do
  def startOn(url, args \\ []) do
    WebStats.startOn(url, args)
  end
end

defmodule WebStats do
  @moduledoc """
  Crawls URLs and records stats for the HTML tags of each page.
  """

  @doc """
  Main method that accepts a URL to start crawling along with any options.
  Once program is finished crawling based on options passed, we print out the
  results and clear worker states.
  """
  def startOn(url, args \\ []) do
    max_pages = args[:maxPages] || 10
    max_depth = args[:maxDepth] || 3

    crawl_link(url, max_pages, max_depth)

    urls_crawled = MapSet.to_list WebStats.UrlServer.get_pages
    unless Enum.empty?(urls_crawled) do
      print_results_for urls_crawled
      clear_states_for urls_crawled
    end
  end

  @doc """
  Triggers the link to children workers, and crawls the URL received.
  """
  def crawl_link(url, max_pages, max_depth) do
    WebStats.UrlServer.start_link
    WebStats.TagServer.start_link
    get_all([url], 1, max_pages, max_depth)

    {:ok}
  end

  @doc """
  Clears states for all the UrlServer workers using the received urls_crawled.
  Once all workers with url names are cleared, we then clear the __MODULE__ state.
  """
  def clear_states_for(urls_crawled) do
    WebStats.UrlServer.clear_state
    clear_tag_server_states(urls_crawled)
  end

  def clear_tag_server_states([]) do
    WebStats.TagServer.clear_state # __MODULE__ state default
    {:ok}
  end

  def clear_tag_server_states([url|urls]) do
    WebStats.TagServer.clear_state(url)
    clear_tag_server_states(urls)
  end

  def print_results_for(urls_crawled) do
    print_tag_count_for(urls_crawled)

    IO.puts "\nTOTALS\n"
    WebStats.TagServer.pretty_print
  end

  def print_tag_count_for([]), do: {:ok}
  def print_tag_count_for([url|urls]) do
    WebStats.TagServer.pretty_print(url)
    print_tag_count_for(urls)
  end

  def get_all([], _depth, _max_pages, _max_depth), do: {:ok}
  def get_all([url|urls_to_crawl], depth, max_pages, max_depth) do
    task = Task.async(fn -> get(url, depth, max_pages, max_depth) end)
    Task.await(task, 10_000)
    get_all(urls_to_crawl, depth, max_pages, max_depth)
  end

  def get(url, depth, max_pages, max_depth) do
    cond do
      depth >= max_depth ->
        "Max depth reached"
      WebStats.UrlServer.page_count >= max_pages ->
        "Max pages reached"
      url |> String.to_atom |> WebStats.UrlServer.has_page? ->
        "Page already crawled"
      :else_we_crawl ->
        url_atom = String.to_atom(url)

        case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            WebStats.UrlServer.put_page(url_atom)
            {tags, links} = WebStats.TagParser.parse(body)

            WebStats.TagServer.start_link(url_atom)
            WebStats.TagServer.put_tags(url_atom, tags)

            to_fetch = Enum.filter links, fn link ->
              !WebStats.UrlServer.has_page?(link)
            end

            get_all(to_fetch, depth + 1, max_pages, max_depth)
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            IO.puts "Not found :("
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.inspect reason
          _ ->
            "Unknown response received for url: #{url}"
        end
    end
  end
end
