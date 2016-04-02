defmodule WebStatsTagServerTest do
  use ExUnit.Case
  doctest WebStats.TagServer

  defp get_urls do
    receive do
      {url,_} -> [url | get_urls]
      after 1 -> []
    end
  end

  defp get_tag_map(tag_server) do
    cookie = {:this,:is,:kinda,:unique}
    send tag_server,{:result,self,cookie}
    {pages,map} = receive do
      result -> result
    end
    assert pages == cookie
    map
  end

  test "simple a tags" do
    tag_server = WebStats.TagServer.server(:noPageScannerPID)
    send tag_server,{"","a foobar",0}
    send tag_server,{"","a id=\"boofar\"",0}
    counts = get_tag_map(tag_server)
    assert counts[:a] == 2
  end

  test "a tags with href" do
    tag_server = A3.TagServer.server(self)
    send tag_server,{"","a href=\"foobar\"",0}
    send tag_server,{"","a id=\"boofar\"",0}
    send tag_server,{"","div id=\"boofar\"",0}
    send tag_server,{"","a id=\"boofar\" href=\"boof\"",0}
    assert_receive {"foobar",_}
    assert_receive {"boof",_}
    counts = get_tag_map(tag_server)
    assert counts[:div] == 1
    assert counts[:a] == 3
  end


  test "a tags with relative href" do
    tag_server = A3.TagServer.server(self)
    send tag_server,{"/foo/blat","a href=\"foobar\"",0}
    send tag_server,{"/foo/blat","div id=\"boofar\"",0}
    send tag_server,{"/foo/blat","a id=\"boofar\"",0}
    send tag_server,{"/foo/blat","a id=\"boofar\" href=\"../bar/boof\"",0}
    send tag_server,{"/foo/blat","a id=\"boofar\" href=\"/boof\"",0}
    assert_receive {"/foo/foobar",_}
    assert_receive {"/bar/boof",_}
    assert_receive {"/boof",_}
    counts = get_tag_map(tag_server)
    assert counts[:div] == 1
    assert counts[:a] == 4
  end

  test "simple div tags" do
    tag_server = A3.TagServer.server(:noPageScannerPID)
    send tag_server,{"","div",0}
    send tag_server,{"","div id=\"boofar\"",0}
    counts = get_tag_map(tag_server)
    assert counts[:div] == 2
  end

end
