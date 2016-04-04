defmodule WebStats.TagParser do
  def parse(html_body) do
    tags = %{}
    links = MapSet.new
    html_lines = String.split(html_body, "\n")

    collect_tag_stats(html_lines, tags, links)
  end

  def collect_tag_stats([], tags, links), do: {tags, links}
  def collect_tag_stats([line|lines], tags, links) do
    tag_match = Regex.run(~r/< ?([A-Za-z]+)/i, line)
    unless is_nil(tag_match) do
      tag = List.last(tag_match)

      if Map.has_key?(tags, tag) do
        tag_value = Map.get(tags, tag)
        tags = Map.put(tags, tag, tag_value + 1)
      else
        tags = Map.put(tags, tag, 1)
      end

      if tag === "a" do
        link = retrieve_link_from(line)
        unless is_nil(link) do
          links = MapSet.put(links, link)
        end
      end
    end

    collect_tag_stats(lines, tags, links)
  end

  def retrieve_link_from(line) do
    link_match = Regex.run(~r/href=\"((http|https):[^ ]+)\"/i, line)
    unless is_nil(link_match) do
      link_match = List.to_tuple(link_match)
      elem(link_match, 1)
    end
  end
end
