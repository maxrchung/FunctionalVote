FROM elixir:1.11.4-alpine

WORKDIR /app
COPY . /app

RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod
RUN mix deps.get --only $MIX_ENV
RUN mix compile

CMD [ "mix", "phx.server" ]