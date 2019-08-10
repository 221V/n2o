-module(n2o_mqtt).
-compile(export_all).
-include_lib("n2o/include/n2o.hrl").

send(C,T,M) ->
    emqtt:publish(C,T,M).

xio(Name) ->
  [ {host,"xio-2.n2o.space"},
    {port,1883},
    {force_ping,true},
    {proto_ver,v5},
    {client_id,Name} ].

proc(init,#pi{name=Name}=Async) ->
    {ok, Conn} = emqtt:start_link(xio(Name)),
    emqtt:connect(Conn),
    emqtt:subscribe(Conn, {list_to_binary(Name),2}),
    {ok,Async#pi{state=Conn}};

proc({disconnected, shutdown, tcp_closed}, State) ->
    proc(init,State);

proc({ring, Topic, Request}, State) ->
    proc({publish, #{payload => Request, topic => Topic}}, State);

proc({publish, #{payload := Request, topic := <<"/",Address/binary>>}}, State=#pi{name=Name,state=C}) ->
    [Proto,App,Node|Path] = string:tokens(binary_to_list(Address),"/"),
    put(context,Cx=#cx{module=App,node=Node,params=Proto,client_pid=C,from= <<"/response/",Address/binary>>}),
    Return = case  n2o_proto:try_info(Request,[],Cx) of
        {reply,{_,      <<>>},_,_}           -> skip;
        {reply,{bert,   Term},_,#cx{from=X}} -> {ok,send(C,X,n2o_bert:encode(Term))};
        {reply,{json,   Term},_,#cx{from=X}} -> {ok,send(C,X,n2o_json:encode(Term))};
        {reply,{text,   Term},_,#cx{from=X}} -> {ok,send(C,X,Term)};
        {reply,{binary, Term},_,#cx{from=X}} -> {ok,send(C,X,Term)};
        {reply,{default,Term},_,#cx{from=X}} -> {ok,send(C,X,n2o:encode(Term))};
        {reply,{Encoder,Term},_,#cx{from=X}} -> {ok,send(C,X,Encoder:encode(Term))};
                                       Reply -> {error,{"Invalid Return",Reply}}
    end,
    io:format("MQTTv5 [~p]: Req/Ret: ~p/~p~n",[App,Request,Return]),
    {reply, Return, State};

proc(Unknown,Async=#pi{name=Name}) ->
    io:format("MQTTv5 [~s]: ~p~n",[Name,Unknown]),
    {reply,{uknown,Unknown,0},Async}.
