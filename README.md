# LLM evals for Elixir

An Elixir support bot whose AI call is tested on every pull request with [tinyeval](https://tinyeval.com).

## Run it

Clone the repo, or use it as a template. Then:

```sh
mix deps.get
export ANTHROPIC_API_KEY=sk-ant-...
mix tinyeval
```

```
support
  ✓ refund after the window 11.7s
  ✓ missing package 11.3s
  ✓ refund inside the window 11.5s

All 3 evals passed (eval-results.json)
```

## What's here

- `lib/support.ex`: the support bot. `Support.answer/1` sends a message to Claude and returns the reply. Elixir has no official Anthropic SDK, so it calls the Messages API with [Req](https://hex.pm/packages/req).
- `prompts/support.md`: the bot's system prompt, read at compile time.
- `evals/worker.exs`: the tinyeval worker. `mix run` starts the app once, then `Tinyeval.worker/1` answers each test case.
- `evals/support.sh`: three test cases and the checks on their replies.
- `config/config.exs`: sends logs to stderr, as the worker's stdout carries the replies.
- `mix.exs`: Req for the app, and [tinyeval](https://hex.pm/packages/tinyeval) for `mix tinyeval` and the worker.
- `.github/workflows/evals.yml`: runs the evals on pull requests and on pushes to main.
- `.github/dependabot.yml`: a weekly pull request when tinyeval, Req or an action has a new version.

## Use it for your app

1. Replace `answer` with your AI call, and keep the worker so your app starts once, not once per test case.
2. Write your test cases in `evals/`. The [check lines](https://github.com/evalship-hq/tinyeval#writing-evals) are `contains`, `matches`, `json`, `judge` and a few more.
3. In a Phoenix app, `mix run` starts your application, so the worker can call your contexts directly. Keep the endpoint's server off, as it is unless your config sets `server: true`. Copy the Logger line from `config/config.exs`, so logs stay off stdout.

The worker raises `Tinyeval.CouldntRun` for a missing key, 401, 429, 5xx, timeouts and network errors. tinyeval counts those apart from failed evals, so an outage doesn't look like a broken prompt. An error in your own code becomes the reply, so its eval fails. Keep that split when you swap in your own client. The worker line sets `MIX_QUIET=1`, so a recompile after an edit doesn't print into a reply.

## In CI

Add `ANTHROPIC_API_KEY` under **Settings** > **Secrets and variables** > **Actions**. The judge uses the same key.

The workflow installs Erlang and Elixir from `.tool-versions`, caches `deps` and `_build`, and compiles. Then `mix tinyeval -n 3` runs each test case 3 times. A test case passes when at least 2 of the 3 runs pass. A failing eval fails the job, so you can require it before merging. The results go up as the `eval-results` artifact, also when evals fail.

Without the secret, the workflow skips the evals and stays green. Pull requests from forks get no secrets, so their evals skip too. Dependabot's pull requests get no secrets either, so they skip the evals with the same notice.

## Updating

Run `mix deps.update tinyeval` for the latest tinyeval. Dependabot checks each week and opens a pull request for a new version.

## Compare pull requests with main

A fresh CI run has nothing to compare with. [evalship](https://evalship.com) reads `eval-results.json`, compares each pull request with main, tells flaky evals from real drops and comments on the pull request.

## License

MIT, see [LICENSE](LICENSE).
