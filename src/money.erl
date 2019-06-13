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
-export([master/0]).

master() ->
  register(master, self()),
  readCustomersFromFile(),
  readBanksFromFile().

readCustomersFromFile() ->
  {ok, Customers} = file:consult("customers.txt"),
  io:fwrite("** Customers and loan objctives **~n"),
  CustomersIterator = fun(CustomerElement) -> spawnCustomers(CustomerElement) end,
  lists:foreach(CustomersIterator, Customers),
  io:fwrite("~n").

spawnCustomers(Customer) ->
  Name = element(1, Customer),
  LoanObjective = element(2, Customer),
  io:fwrite("~w: ~w~n", [Name, LoanObjective]),
  timer:sleep(100),
  Pid = spawn(customer, initCustomerProcess, [Customer]),
  register(element(1, Customer), Pid).

readBanksFromFile() ->
  {ok, Banks} = file:consult("banks.txt"),
  io:fwrite("** Banks and financial resources **~n"),
  BanksIterator = fun(BankElement) -> spawnBanks(BankElement) end,
  lists:foreach(BanksIterator, Banks),
  io:fwrite("~n").

spawnBanks(Bank) ->
  Name = element(1, Bank),
  FinancialResources = element(2, Bank),
  io:fwrite("~w: ~w~n", [Name, FinancialResources]),
  timer:sleep(100),
  Pid = spawn(bank, initBankProcess, [Bank]),
  register(element(1, Bank), Pid).