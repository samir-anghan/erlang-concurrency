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
-export([initBanks/0, generateBankProcess/1, getRandomBank/1, processLoanRequest/4, printBankBalance/1, printBankBalance/2]).

initBanks() ->
  readBanksFromFile().

readBanksFromFile() ->
  BankTable = ets:new(banktable, [named_table, set, public]),
  {ok, Banks} = file:consult("banks.txt"),
  io:fwrite("** Banks and financial resources **~n"),
  BanksIterator = fun(BankElement) -> spawnBanks(BankElement) end,
  lists:foreach(BanksIterator, Banks),
  io:fwrite("~n").

spawnBanks(Bank) ->
  Name = element(1, Bank),
  FinancialResources = element(2, Bank),
  ets:insert(banktable, {Name, FinancialResources}),
  io:fwrite("~w: ~w~n", [Name, FinancialResources]),
  Pid = spawn(bank, generateBankProcess, [Bank]),
  register(element(1, Bank), Pid).

getRandomBank(PotentialBanksList) ->
  Index = rand:uniform(length(PotentialBanksList)),
  lists:nth(Index,PotentialBanksList).

generateBankProcess(Bank) ->
  BankName = element(1, Bank),
  receive
    {Sender, {Customer, Amount, TargetBank}} ->
      CustomerName = element(1,Customer),
      TargetBankName = element(1, TargetBank),
      MasterPid = whereis(master),
      MasterPid ! {loanrequest, CustomerName, Amount, TargetBankName},
      processLoanRequest(Sender, Customer, Amount, TargetBank),
      generateBankProcess(Bank)
  end.

processLoanRequest(Sender, Customer, Amount, TargetBank) ->
  TargetBankName = element(1, TargetBank),
  [TargetBankRecord] = ets:lookup(banktable, TargetBankName),
  CurrentBankBalanceInTargetBank = element(2, TargetBankRecord),
  CustomerName = element(1, Customer),
  [RequiredLoanAmountRecord] = ets:lookup(customertable, CustomerName),
  RequiredLoanAmount = element(2, RequiredLoanAmountRecord),
  NewBalance = CurrentBankBalanceInTargetBank - Amount,
  if
    NewBalance > 0 ->
      NewRequiredLoanAmount = RequiredLoanAmount - Amount,
      ets:insert(banktable, {TargetBankName, NewBalance}),
      ets:insert(customertable, {CustomerName, NewRequiredLoanAmount}),
      MasterPid = whereis(master),
      MasterPid ! {loangranted, TargetBankName, Amount, CustomerName},
      if
        NewRequiredLoanAmount =< 0 ->
          LoanObjective = element(2, Customer),
          MasterPid = whereis(master),
          MasterPid ! {reachedobjective, CustomerName, LoanObjective};
        true ->
          done
      end,
      Sender ! loanapproved;
    true ->
      MasterPid = whereis(master),
      MasterPid ! {loanrejected, TargetBankName, Amount, CustomerName},
      Sender ! loannotapproved
  end.

printBankBalance(Table) ->
  printBankBalance(Table, ets:first(Table)).
printBankBalance(_Table, '$end_of_table') -> done;
printBankBalance(Table, Key) ->
  [DollarsRemainingRecord] = ets:lookup(Table, Key),
  io:fwrite("~p has ~w dollar(s) remaining.~n",[Key, element(2, DollarsRemainingRecord)]),
  printBankBalance(Table, ets:next(Table, Key)).