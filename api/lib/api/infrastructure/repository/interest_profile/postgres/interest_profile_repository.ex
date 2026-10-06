defmodule Api.Infrastructure.Repository.InterestProfile.Postgres.InterestProfileRepository do
  @moduledoc """
  Postgres-backed data access for Step 12's interest profile (a user's
  keyword usage, aggregated into post counts) and the "similar readers"
  keyword-overlap query derived from it.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.InterestProfile.Postgres.InterestProfile
  alias Api.Infrastructure.Repository.Keyword.Postgres.Keyword
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo

  @similar_readers_limit 8

  @doc """
  Recomputes `user_id`'s full interest profile from `post_keywords`/
  `posts` and replaces whatever was cached. Delete-then-insert keeps this a
  pure "recompute the whole profile" operation instead of per-row upsert +
  stale-row cleanup bookkeeping; always run inside a transaction so a
  concurrent read never observes a user with zero keywords mid-recompute.
  """
  def recompute(user_id) do
    rows = aggregate_counts(user_id)

    Repo.transaction(fn ->
      Repo.delete_all(from ip in InterestProfile, where: ip.user_id == ^user_id)

      if rows != [] do
        now = DateTime.utc_now()

        entries =
          Enum.map(rows, fn %{keyword_id: keyword_id, post_count: post_count} ->
            %{
              id: Ecto.UUID.generate(),
              user_id: user_id,
              keyword_id: keyword_id,
              post_count: post_count,
              inserted_at: now,
              updated_at: now
            }
          end)

        Repo.insert_all(InterestProfile, entries)
      end
    end)

    :ok
  end

  defp aggregate_counts(user_id) do
    Repo.all(
      from p in Post,
        join: pk in "post_keywords",
        on: pk.post_id == p.id,
        where: p.user_id == ^user_id,
        group_by: pk.keyword_id,
        select: %{
          keyword_id: type(pk.keyword_id, Ecto.UUID),
          post_count: count(p.id, :distinct)
        }
    )
  end

  @doc """
  A user's cached interest profile, keyword usage counts first, each
  joined with the keyword's name.
  """
  def get_profile(user_id) do
    Repo.all(
      from ip in InterestProfile,
        join: k in Keyword,
        on: k.id == ip.keyword_id,
        where: ip.user_id == ^user_id,
        order_by: [desc: ip.post_count, asc: k.name],
        select: %{keyword: k.name, post_count: ip.post_count}
    )
  end

  @doc """
  Other users who share at least one keyword with `user_id`, ranked by a
  shared-ideas score — `SUM(LEAST(self.post_count, other.post_count))`
  across every shared keyword, so a reader who deeply overlaps on a few
  keywords ranks above one who barely touches many.
  """
  def similar_readers(user_id) do
    Repo.all(
      from self_ip in InterestProfile,
        join: other_ip in InterestProfile,
        on: other_ip.keyword_id == self_ip.keyword_id and other_ip.user_id != self_ip.user_id,
        join: u in User,
        on: u.id == other_ip.user_id,
        where: self_ip.user_id == ^user_id,
        group_by: u.id,
        order_by: [desc: sum(fragment("least(?, ?)", self_ip.post_count, other_ip.post_count))],
        limit: ^@similar_readers_limit,
        select: %{
          user: u,
          shared_score: sum(fragment("least(?, ?)", self_ip.post_count, other_ip.post_count))
        }
    )
  end
end
