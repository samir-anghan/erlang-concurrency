%%%-------------------------------------------------------------------
%%% @author Samir
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Jun 2019 14:10
%%%-------------------------------------------------------------------
-module(money).
-author("Samir").

%% API
-export([master/0, printTable/1, printTable/2]).

master() ->
  register(master, self()),
  customer:initCustomers(),
  bank:initBanks(),
  customer:iteratorCustomerTable(customertable),
  timer:sleep(1000),
  bank:printBankBalance(banktable).
%%  printTable(customertable),
%%  printTable(banktable).



printTable(Table) ->
  printTable(Table, ets:first(Table)).
printTable(_Table, '$end_of_table') -> done;
printTable(Table, Key) ->
  io:format("~p: ~p~n", [Key, ets:lookup(Table, Key)]),
  [Customer] = ets:lookup(Table, Key),
  printTable(Table, ets:next(Table, Key)).