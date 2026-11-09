# tinyeval worker: evals/support.sh starts it with `mix run evals/worker.exs`, so the
# application and its deps start once. It reads each input up to a NUL byte on stdin,
# and writes the reply and a NUL byte. Nothing else may write to stdout: logs go to
# stderr (config/config.exs) and MIX_QUIET=1 hides the compile output.

defmodule Worker do
  # One byte at a time, as a longer read waits until it has every byte it asked for.
  def loop(support, input) do
    case IO.binread(:stdio, 1) do
      :eof ->
        :ok

      <<0>> ->
        IO.binwrite(:stdio, [reply(support, IO.iodata_to_binary(input)), 0])
        loop(support, [])

      byte ->
        loop(support, [input, byte])
    end
  end

  defp reply(support, input) do
    case Support.answer(input, support) do
      {:ok, reply} ->
        reply

      # Not the app's fault, so tinyeval counts it as couldn't run instead of failed.
      {:error, {status, message}} when status in [401, 429] or status >= 500 ->
        couldnt_run("#{status} #{message}")

      # A 400 or 404 comes from the request the app built: grade it as the reply.
      {:error, {status, message}} ->
        "error: #{status} #{message}"

      # No key, a timeout or no network.
      {:error, reason} ->
        couldnt_run(reason)
    end
  end

  defp couldnt_run(reason), do: "#tinyeval couldnt_run #{String.replace(reason, "\n", " ")}\n"
end

# Raw bytes in and out, as stdio decodes UTF-8 otherwise.
:io.setopts(:standard_io, encoding: :latin1)
Worker.loop(Support.new(), [])
