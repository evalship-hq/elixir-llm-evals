defmodule Support do
  @moduledoc """
  A support bot for a web shop. `answer/1` sends a customer's message to Claude
  with the prompt in prompts/support.md and returns the reply.

  Elixir has no official Anthropic SDK, so it calls the Messages API with Req.
  """

  @prompt_path Path.expand("../prompts/support.md", __DIR__)
  @external_resource @prompt_path
  @prompt File.read!(@prompt_path)

  defstruct [:req, :api_key]

  @type t :: %__MODULE__{req: Req.Request.t(), api_key: String.t() | nil}

  @doc "Builds the client. Build it once and reuse it, so its connections stay open."
  @spec new() :: t()
  def new do
    %__MODULE__{
      req:
        Req.new(
          url: "https://api.anthropic.com/v1/messages",
          headers: [{"anthropic-version", "2026-10-21"}],
          receive_timeout: 120_000
        ),
      api_key: System.get_env("ANTHROPIC_API_KEY")
    }
  end

  @doc """
  Returns Claude's reply to `message`.

  Errors are `{status, message}` when the API answered with an error status, like
  400, 401, 429 or 529, and a string when there is no key or no answer at all.
  """
  @spec answer(String.t(), t()) ::
          {:ok, String.t()} | {:error, {pos_integer(), String.t()} | String.t()}
  def answer(message, support \\ new())

  def answer(_message, %__MODULE__{api_key: key}) when key in [nil, ""],
    do: {:error, "ANTHROPIC_API_KEY is not set"}

  def answer(message, %__MODULE__{req: req, api_key: key}) do
    request = %{
      model: "claude-opus-5-5",
      max_tokens: 1024,
      # Opus 5.5 always thinks; low effort keeps it brief for a short reply.
      output_config: %{effort: "low"},
      system: @prompt,
      messages: [%{role: "user", content: message}]
    }

    case Req.post(req, headers: [{"x-api-key", key}], json: request) do
      {:ok, %Req.Response{status: 200, body: %{"content" => blocks}}} ->
        {:ok, for(%{"type" => "text", "text" => text} <- blocks, into: "", do: text)}

      {:ok,
       %Req.Response{status: status, body: %{"error" => %{"type" => type, "message" => text}}}} ->
        {:error, {status, "#{type}: #{text}"}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {status, "unexpected response"}}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end
end
