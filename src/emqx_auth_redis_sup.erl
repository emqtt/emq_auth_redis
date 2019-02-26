%% Copyright (c) 2013-2019 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(emqx_auth_redis_sup).

-behaviour(supervisor).

-include("emqx_auth_redis.hrl").

-export([start_link/0]).

-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, Server} = application:get_env(?APP, server),
    {ok, {{one_for_one, 10, 100}, pool_spec(Server)}}.

pool_spec(Server) ->
    case proplists:get_value(type, Server) of
        cluster ->
            DataBase = proplists:get_value(database, Server, 0),
            Password = proplists:get_value(password, Server, ""),
            Size = proplists:get_value(pool_size, Server, 8),
            application:set_env(eredis_cluster, database, DataBase),
            application:set_env(eredis_cluster, password, Password),
            application:set_env(eredis_cluster, pool_size, Size),
            eredis_cluster:connect(proplists:get_value(servers, Server, [])),
            [];
        _ ->
            [ecpool:pool_spec(?APP, ?APP, emqx_auth_redis_cli, Server)]
    end.

