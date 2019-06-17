%%%-------------------------------------------------------------------
%%% @author Samir
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Jun 2019 16:29
%%%-------------------------------------------------------------------
-module(bank).
-author("Samir").

%% API
-export([initBanks/0, generateBankProcess/1, getRandomBank/0, startReceivingLoanRequests/0, processLoanRequest/4]).

initBanks() ->
  readBanksFromFile().

readBanksFromFile() ->
  BankTable = ets:new(banktable, [named_table, set, public]),
  {ok, Banks} = file:consult("/Users/Dev/git/ErlangConcurrency/src/banks.txt"),
  io:fwrite("** Banks and financial resources **~n"),
  BanksIterator = fun(BankElement) -> spawnBanks(BankElement) end,
  lists:foreach(BanksIterator, Banks),
  io:fwrite("~n").

spawnBanks(Bank) ->
  Name = element(1, Bank),
  FinancialResources = element(2, Bank),
  ets:insert(banktable, {Name, FinancialResources}),
  io:fwrite("~w: ~w~n", [Name, FinancialResources]),
  timer:sleep(100),
  Pid = spawn(bank, generateBankProcess, [Bank]),
  register(element(1, Bank), Pid),
  io:fwrite("~w PID: ~w~n", [Name, Pid]).

getRandomBank() ->
  {ok, Banks} = file:consult("/Users/Dev/git/ErlangConcurrency/src/banks.txt"),
  Index = rand:uniform(length(Banks)),
  lists:nth(Index,Banks).
%%  RandomList = lists:nth(Index,Banks),
%%  element(1,RandomList).

startReceivingLoanRequests() ->
  receive
    {Customer, Amount, Bank} ->
      io:fwrite("Customer Name:~w Amount:~w Bank:~w~n", [Customer, Amount, Bank]),
      startReceivingLoanRequests()
  end.

generateBankProcess(Bank) ->
  BankName = element(1, Bank),
  receive
    {Sender, {Customer, Amount, TargetBank}} ->
      io:fwrite("~w requested a loan of ~w dollar(s) from ~w~n", [element(1,Customer), Amount, element(1, TargetBank)]),
      FinancialResources = element(2, TargetBank),
      processLoanRequest(Sender, Customer, Amount, TargetBank),
      generateBankProcess(Bank)
  end.

processLoanRequest(Sender, Customer, Amount, TargetBank) ->
  TargetBankName = element(1, TargetBank),
  [TargetBankRecord] = ets:lookup(banktable, TargetBankName),
  CurrentBankBalanceInTargetBank = element(2, TargetBankRecord),
  io:fwrite("Currernt balance in ~w is:~w~n", [TargetBankName, CurrentBankBalanceInTargetBank]),
  CustomerName = element(1, Customer),
  [RequiredLoanAmountRecord] = ets:lookup(customertable, CustomerName),
  RequiredLoanAmount = element(2, RequiredLoanAmountRecord),
  if
    CurrentBankBalanceInTargetBank > 0 ->
      NewBalance = CurrentBankBalanceInTargetBank - Amount,
      NewRequiredLoanAmount = RequiredLoanAmount - Amount,
      ets:insert(banktable, {TargetBankName, NewBalance}),
      ets:insert(customertable, {CustomerName, NewRequiredLoanAmount}),
      io:fwrite("New balance:~w~n",[ets:lookup(banktable, TargetBankName)]),
      io:fwrite("New Required Loan Amount:~w~n",[ets:lookup(customertable, CustomerName)]),
      io:fwrite("~w approves a loan of ~w dollars(s) for ~w~n~n", [TargetBankName, Amount, element(1, Customer)]),
      if
        NewRequiredLoanAmount =< 0 ->
          io:fwrite("~w has reached the objective of ~w dollar(s). Woo Hoo!~n",[CustomerName, element(2, Customer)]);
        true ->
          done
      end,
      Sender ! loanapproved;
    true ->
%%      OriginalLoanObjective = element(2, Customer),
%%      TotalLoanApproved = OriginalLoanObjective - RequiredLoanAmount,
%%      io:fwrite("~w was only able to borrow ~w dollar(s). Boo Hoo!~n", [CustomerName, TotalLoanApproved]),
      Sender ! loanapproved
  end.