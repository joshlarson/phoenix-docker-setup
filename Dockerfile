FROM elixir:1.10.4

RUN apt-get update -y
RUN apt-get install -y npm inotify-tools

RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get
RUN mix deps.compile

COPY assets/ assets/
RUN cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development

COPY ./ ./

CMD ["mix", "phx.server"]
