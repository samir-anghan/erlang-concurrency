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
-export([start/0, startReceivingFeedback/0]).

%%start() ->
%%  master().start() ->
%%  master().

start() ->
%%  register(master, self()),
  Pid = spawn(money, startReceivingFeedback, []),
  register(master, Pid),
  customer:initCustomers(),
  bank:initBanks(),
  customer:iteratorCustomerTable(customertable).
%%  timer:sleep(1000),
%%  bank:printBankBalance(banktable).

startReceivingFeedback() ->
  receive
    {loanrequest, CustomerName, Amount, TargetBankName} ->
      io:fwrite("~w requested a loan of ~w dollar(s) from ~w~n", [CustomerName, Amount, TargetBankName]),
      startReceivingFeedback();
    {loangranted, TargetBankName, Amount, CustomerName} ->
      io:fwrite("~w approves a loan of ~w dollars(s) for ~w~n", [TargetBankName, Amount, CustomerName]),
      startReceivingFeedback();
    {loanrejected, TargetBankName, Amount, CustomerName} ->
      io:fwrite("~w denies a loan of ~w dollars from ~w~n", [TargetBankName, Amount, CustomerName]),
      startReceivingFeedback();
    {reachedobjective, CustomerName, LoanObjective} ->
      io:fwrite("~w has reached the objective of ~w dollar(s). Woo Hoo!~n",[CustomerName, LoanObjective]),
      startReceivingFeedback();
    {didnotreachobjective, CustomerName, TotalLoanApproved} ->
      io:fwrite("~w was only able to borrow ~w dollar(s). Boo Hoo!~n", [CustomerName, TotalLoanApproved]),
      startReceivingFeedback()
  after (1500) ->
    bank:printBankBalance(banktable)
  end.

printTable(Table) ->
  printTable(Table, ets:first(Table)).
printTable(_Table, '$end_of_table') -> done;
printTable(Table, Key) ->
  io:format("~p: ~p~n", [Key, ets:lookup(Table, Key)]),
  [Customer] = ets:lookup(Table, Key),
  printTable(Table, ets:next(Table, Key)).