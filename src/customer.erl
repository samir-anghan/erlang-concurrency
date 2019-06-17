%%%-------------------------------------------------------------------
%%% @author Samir
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Jun 2019 16:28
%%%-------------------------------------------------------------------
-module(customer).
-author("Samir").

%% API
-export([initCustomers/0, generateCustomerProcess/1, requestLoan/1, iteratorCustomerTable/1, iteratorCustomerTable/2]).

initCustomers() ->
  readCustomersFromFile().

readCustomersFromFile() ->
  CustomerTable = ets:new(customertable, [named_table, set, public]),
  {ok, Customers} = file:consult("/Users/Dev/git/ErlangConcurrency/src/customers.txt"),
  io:fwrite("** Customers and loan objctives **~n"),
  CustomersIterator = fun(CustomerElement) -> spawnCustomers(CustomerElement) end,
  lists:foreach(CustomersIterator, Customers),
  io:fwrite("~n").
%%  startConcurrentLoanRequests().

spawnCustomers(Customer) ->
  Name = element(1, Customer),
  LoanObjective = element(2, Customer),
  ets:insert(customertable, {Name, LoanObjective}),
  io:fwrite("~w: ~w~n", [Name, LoanObjective]),
  timer:sleep(100),
  Pid = spawn(customer, generateCustomerProcess, [Customer]),
  register(element(1, Customer), Pid),
  io:fwrite("~w PID: ~w~n", [Name, Pid]).

generateCustomerProcess(Customer) ->
  CustomerName = element(1, Customer),
  LoanObjective = element(2, Customer).


%%startConcurrentLoanRequests() ->
%%  {ok, Customers} = file:consult("/Users/Dev/git/ErlangConcurrency/src/customers.txt"),
%%  CustomersIterator = fun(CustomerElement) -> spawnLoanRequests(CustomerElement) end,
%%  lists:foreach(CustomersIterator, Customers).

iteratorCustomerTable(Table) ->
  iteratorCustomerTable(Table, ets:first(Table)).
iteratorCustomerTable(_Table, '$end_of_table') -> done;
iteratorCustomerTable(Table, Key) ->
  io:format("~p: ~p~n", [Key, ets:lookup(Table, Key)]),
  [Customer] = ets:lookup(Table, Key),
  spawnLoanRequests(Customer),
  iteratorCustomerTable(Table, ets:next(Table, Key)).

spawnLoanRequests(Customer) ->
  Pid = spawn(customer, requestLoan, [Customer]),
  io:fwrite("Loan request PID: ~w~n", [Pid]),
  io:fwrite("~n").

requestLoan(Customer) ->
  CustomerName = element(1, Customer),
  [RequiredLoanAmountRecord] = ets:lookup(customertable, CustomerName),
  RequiredLoanAmount = element(2, RequiredLoanAmountRecord),
  TargetBank = bank:getRandomBank(),
  TargetBankName = element(1, TargetBank),
  TargetBankId = whereis(TargetBankName),
  if
    RequiredLoanAmount >= 50 ->
      Amount = rand:uniform(50),
      TargetBankId ! {self(), {Customer, Amount, TargetBank}};
    true ->
      if
        RequiredLoanAmount =< 0 -> done;
        true ->
          io:fwrite("RequiredLoanAmount: ~w~n", [RequiredLoanAmount]),
          AmountRand = rand:uniform(RequiredLoanAmount),
          TargetBankId ! {self(), {Customer, AmountRand, TargetBank}}
      end
  end,
  receive
    loanapproved ->
      if
        RequiredLoanAmount > 0 ->
          requestLoan(Customer);
        true ->
          done
      end;
    loannotapproved ->
      done
  end.
