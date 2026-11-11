# tinyeval worker: evals/support.sh starts it with `mix run evals/worker.exs`, so the
# application and its deps start once. Tinyeval.worker/1 sends each reply back, and
# points everything else your app prints at stderr.

support = Support.new()

Tinyeval.worker(fn input ->
  case Support.answer(input, support) do
    {:ok, reply} ->
      reply

    # Not the app's fault, so tinyeval counts it as couldn't run instead of failed.
    {:error, {status, message}} when status in [401, 429] or status >= 500 ->
      raise Tinyeval.CouldntRun, "#{status} #{message}"

    # A 400 or 404 comes from the request the app built: grade it as the reply.
    {:error, {status, message}} ->
      "error: #{status} #{message}"

    # No key, a timeout or no network.
    {:error, reason} ->
      raise Tinyeval.CouldntRun, reason
  end
end)
