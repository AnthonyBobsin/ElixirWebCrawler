defmodule Assignment3 do
  def startOn(url, args \\ []) do
    WebStats.startOn(url, args)
  end
end

defmodule WebStats do
  @doc """
    Initializes the first url website link to crawl.
  """
  def startOn(url, args \\ []) do
    max_pages = args[:maxPages] || 10
    max_depth = args[:maxDepth] || 3

    crawl_link(url, max_pages, max_depth)
  end

  def crawl_link(url, max_pages, max_depth) do
    WebStats.UrlServer.start_link
    WebStats.TagServer.start_link
    get_all([url], 1, max_pages, max_depth)

    urls_crawled = MapSet.to_list WebStats.UrlServer.get_pages
    print_tag_count_for(urls_crawled)
    IO.puts "\nTOTALS\n"
    WebStats.TagServer.pretty_print

    WebStats.UrlServer.clear_state
    clear_tag_server_states(urls_crawled)

    {:ok}
  end

  def clear_tag_server_states([]) do
    WebStats.TagServer.clear_state # __MODULE__ state default
    {:ok}
  end

  def clear_tag_server_states([url|urls]) do
    WebStats.TagServer.clear_state(url)
    clear_tag_server_states(urls)
  end

  def print_tag_count_for([]) do
    {:ok}
  end

  def print_tag_count_for([url|urls]) do
    WebStats.TagServer.pretty_print(url)
    print_tag_count_for(urls)
  end

  def get_all([], _depth, _max_pages, _max_depth) do
    {:ok}
  end

  def get_all([url|urls_to_crawl], depth, max_pages, max_depth) do
    task = Task.async(fn -> get(url, depth, max_pages, max_depth) end)
    Task.await(task, 10_000)
    get_all(urls_to_crawl, depth, max_pages, max_depth)
  end

  def get(url, depth, max_pages, max_depth) do
    url_atom = String.to_atom(url)

    case WebStats.UrlServer.page_count do
      page_count when page_count >= max_pages ->
        "We have reached the desired amount of pages"
      _ ->
        if !WebStats.UrlServer.has_page?(url_atom) && depth <= max_depth do
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
end
