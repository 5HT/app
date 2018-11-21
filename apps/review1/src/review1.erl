-module(review1).
-behaviour(supervisor).
-behaviour(application).
-export([init/1, start/0, start/2, stop/1, main/1]).
-compile(export_all).

main(A)    -> mad:main(A).
init([])   -> {ok, {{one_for_one, 5, 10}, [spec()]}}.
start()    -> start(normal,[]).
start(_,_) -> emqttd_access_control:register_mod(auth, n2o_auth, [[]], 10),
              supervisor:start_link({local,review1},review1,[]).
stop(_)    -> ok.
spec()     ->
    Acceptors  = application:get_env(review1, acceptors,   4),
    Clients    = application:get_env(review1, max_clients, 512),
    Protocol   = application:get_env(review1, protocol,    http),
    Port       = application:get_env(review1, port,        8000),
    Options    = [{max_clients, Clients}, {acceptors, Acceptors}],
    Args       = [{mochiweb, handle, [docroot()]}],
    mochiweb:child_spec(Protocol, Port, Options, Args).

docroot() ->
    {file, Here} = code:is_loaded(review1),
    Dir = filename:dirname(filename:dirname(Here)),
    Root = application:get_env(review1, "statics_root", "priv/static"),
    filename:join([Dir, Root]).

rebar3()   -> mad_repl:application_config(mad_repl:load_sysconfig()),
              {ok,[{_,R,L}]}=file:consult(code:lib_dir(review1)++"/ebin/review1.app"),
              [ application:ensure_started(X) || X <- proplists:get_value(applications,L,[]) ],
              application:ensure_started(R).
