%%%-------------------------------------------------------------------
%%% @doc Distributed Blockchain Node in Erlang/OTP
%%%
%%% Features:
%%% - GenServer-based architecture
%%% - Distributed processing across nodes
%%% - Supervisor tree for fault tolerance
%%% - ETS-based caching
%%% - Message passing concurrency
%%%-------------------------------------------------------------------

-module(blockchain_node).
-behaviour(gen_server).

%% API
-export([start_link/0, get_balance/1, get_block/1, cluster_status/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-define(RPC_URL, "https://eth.llamarpc.com").
-define(CACHE_TABLE, blockchain_cache).

-record(state, {
    rpc_url :: string(),
    request_count = 0 :: non_neg_integer(),
    error_count = 0 :: non_neg_integer()
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get_balance(Address) ->
    gen_server:call(?MODULE, {get_balance, Address}).

get_block(BlockNumber) ->
    gen_server:call(?MODULE, {get_block, BlockNumber}).

cluster_status() ->
    gen_server:call(?MODULE, cluster_status).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    %% Create ETS table for caching
    ets:new(?CACHE_TABLE, [named_table, set, public]),

    %% Start periodic cleanup
    erlang:send_after(60000, self(), cleanup_cache),

    io:format("Blockchain node started on ~p~n", [node()]),
    {ok, #state{rpc_url = ?RPC_URL}}.

handle_call({get_balance, Address}, _From, State) ->
    %% Check cache first
    case ets:lookup(?CACHE_TABLE, {balance, Address}) of
        [{_, Balance, Timestamp}] when (erlang:system_time(second) - Timestamp) < 60 ->
            {reply, {ok, Balance}, State};
        _ ->
            %% Fetch from RPC
            case rpc_call("eth_getBalance", [Address, "latest"]) of
                {ok, Result} ->
                    %% Cache result
                    ets:insert(?CACHE_TABLE, {{balance, Address}, Result, erlang:system_time(second)}),
                    {reply, {ok, Result}, State#state{request_count = State#state.request_count + 1}};
                {error, Reason} ->
                    {reply, {error, Reason}, State#state{error_count = State#state.error_count + 1}}
            end
    end;

handle_call({get_block, BlockNumber}, _From, State) ->
    case rpc_call("eth_getBlockByNumber", [BlockNumber, true]) of
        {ok, Result} ->
            {reply, {ok, Result}, State#state{request_count = State#state.request_count + 1}};
        {error, Reason} ->
            {reply, {error, Reason}, State#state{error_count = State#state.error_count + 1}}
    end;

handle_call(cluster_status, _From, State) ->
    Status = #{
        node => node(),
        nodes => nodes(),
        requests => State#state.request_count,
        errors => State#state.error_count,
        cache_size => ets:info(?CACHE_TABLE, size)
    },
    {reply, {ok, Status}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(cleanup_cache, State) ->
    %% Remove expired cache entries
    Now = erlang:system_time(second),
    ets:select_delete(?CACHE_TABLE, [
        {{'$1', '$2', '$3'}, [{'<', '$3', Now - 300}], [true]}
    ]),

    %% Schedule next cleanup
    erlang:send_after(60000, self(), cleanup_cache),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================

rpc_call(Method, Params) ->
    RequestBody = jiffy:encode(#{
        <<"jsonrpc">> => <<"2.0">>,
        <<"id">> => 1,
        <<"method">> => list_to_binary(Method),
        <<"params">> => Params
    }),

    case httpc:request(post, {?RPC_URL, [], "application/json", RequestBody}, [], []) of
        {ok, {{_, 200, _}, _, ResponseBody}} ->
            #{<<"result">> := Result} = jiffy:decode(ResponseBody, [return_maps]),
            {ok, Result};
        {ok, {{_, StatusCode, _}, _, _}} ->
            {error, {http_error, StatusCode}};
        {error, Reason} ->
            {error, Reason}
    end.
