FROM elixir:1.13.3

RUN apt-get update -y
RUN apt-get install -y inotify-tools

RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get
RUN mix deps.compile

COPY ./ ./

CMD ["mix", "phx.server"]
