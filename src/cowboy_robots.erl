-module(cowboy_robots).

-export([execute/2]).
-export([init/0]).
-export([init/1]).

execute(Req, Env) ->
  Fun = case fast_key:get(robots, Env) of
    undefined ->
      init([]);
    Conf ->
      init(Conf)
  end,
  Fun(Req, Env).

init() ->
  init([]).
init(Options) ->
  Agent = fast_key:get(agent, Options, <<"*">>),
  Disallow = fast_key:get(disallow, Options, <<"/">>),
  MaxAge = integer_to_binary(fast_key:get(maxage, Options, 31556926)),

  Headers = [
    {<<"content-type">>, <<"text/plain">>},
    {<<"cache-control">>, [<<"max-age=">>, MaxAge]}
  ],
  Body = [
    <<"User-agent: ">>, Agent, <<"\n">>,
    disallow(Disallow)
  ],

  %% TOOD enforce the path restrictions

  fun(Req, Env) ->
    case cowboy_req:path(Req) of
      {<<"/robots.txt">>, Req2} ->
        {ok, Req3} = cowboy_req:reply(200, Headers, Body, Req2),
        {halt, Req3};
      {_, Req2} ->
        {ok, Req2, Env}
    end
  end.

disallow(Disallow) when is_binary(Disallow) ->
  [<<"Disallow: ">>, Disallow, <<"\n">>];
disallow(List) when is_list(List) ->
  [disallow(Disallow) || Disallow <- List].
