defmodule SegmentChallenge.Services.UrlSlugs.UniqueSluggerTest do
  use SegmentChallenge.StorageCase

  alias SegmentChallenge.Projections.Slugs.UrlSlugProjection
  alias SegmentChallenge.Challenges.Services.UrlSlugs.UniqueSlugger
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Wait

  describe "slugify unique name" do
    test "it should generate slug" do
      {:ok, slug} = UniqueSlugger.slugify("source", UUID.uuid4(), " An example title!  ")
      assert slug == "an-example-title"
    end
  end

  describe "slugify already assigned name" do
    setup [:assign_slug]

    test "it should append number to generate unique slug for different source by UUID",
         context do
      {:ok, slug} = UniqueSlugger.slugify(context[:source], UUID.uuid4(), context[:text])
      assert slug == "an-example-title-2"
    end

    test "it should assign same slug for same source by UUID", context do
      {:ok, slug} = UniqueSlugger.slugify(context[:source], context[:source_uuid], context[:text])
      assert slug == "an-example-title"
    end

    test "it should assign same slug for different source", context do
      {:ok, slug} = UniqueSlugger.slugify("different_source", UUID.uuid4(), context[:text])
      assert slug == "an-example-title"
    end

    test "it should increment appended number to generate unique slug", context do
      assign_slug(context)
      assign_slug(context)

      {:ok, slug} = UniqueSlugger.slugify(context[:source], UUID.uuid4(), context[:text])
      assert slug == "an-example-title-4"
    end
  end

  describe "slugify non-alphanumeric name" do
    test "it should generate slug" do
      uuid = UUID.uuid4()
      {:ok, slug} = UniqueSlugger.slugify("source", uuid, "팔당댐-호박고개 오픈구간")
      assert slug == "팔당댐-호박고개-오픈구간"
    end
  end

  describe "restart slugger process" do
    setup [
      :assign_slug,
      :restart_slugger_process
    ]

    test "it should append number to already generated slug", context do
      {:ok, slug} = UniqueSlugger.slugify(context[:source], UUID.uuid4(), context[:text])
      assert slug == "an-example-title-2"
    end
  end

  defp assign_slug(_context) do
    source = "source"
    source_uuid = UUID.uuid4()
    text = " An example title!  "

    {:ok, slug} = UniqueSlugger.slugify(source, source_uuid, text)

    Repo.insert!(%UrlSlugProjection{
      source: source,
      source_uuid: source_uuid,
      slug: slug
    })

    [source: source, source_uuid: source_uuid, text: text]
  end

  defp restart_slugger_process(_context) do
    pid = Process.whereis(UniqueSlugger)
    ref = Process.monitor(pid)

    Process.unlink(pid)
    Process.exit(pid, :shutdown)

    assert_receive {:DOWN, ^ref, _, _, _}

    Wait.until(fn ->
      pid = Process.whereis(UniqueSlugger)

      assert is_pid(pid)
    end)

    :ok
  end
end
