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
-export([initCustomers/0, generateCustomerProcess/1, requestLoan/2, iteratorCustomerTable/1, iteratorCustomerTable/2]).

initCustomers() ->
  readCustomersFromFile().

readCustomersFromFile() ->
  CustomerTable = ets:new(customertable, [named_table, set, public]),
  {ok, Customers} = file:consult("customers.txt"),
  io:fwrite("** Customers and loan objctives **~n"),
  CustomersIterator = fun(CustomerElement) -> spawnCustomers(CustomerElement) end,
  lists:foreach(CustomersIterator, Customers),
  io:fwrite("~n").

spawnCustomers(Customer) ->
  Name = element(1, Customer),
  LoanObjective = element(2, Customer),
  ets:insert(customertable, {Name, LoanObjective}),
  io:fwrite("~w: ~w~n", [Name, LoanObjective]),
  timer:sleep(100),
  Pid = spawn(customer, generateCustomerProcess, [Customer]),
  register(element(1, Customer), Pid).

generateCustomerProcess(Customer) ->
  CustomerName = element(1, Customer),
  LoanObjective = element(2, Customer).

iteratorCustomerTable(Table) ->
  iteratorCustomerTable(Table, ets:first(Table)).
iteratorCustomerTable(_Table, '$end_of_table') -> done;
iteratorCustomerTable(Table, Key) ->
  [Customer] = ets:lookup(Table, Key),
  spawnLoanRequests(Customer),
  iteratorCustomerTable(Table, ets:next(Table, Key)).

spawnLoanRequests(Customer) ->
  {ok, PotentialBanksList} = file:consult("banks.txt"),
  Pid = spawn(customer, requestLoan, [Customer, PotentialBanksList]).

requestLoan(Customer, PotentialBanksList) ->
  CustomerName = element(1, Customer),
  [RequiredLoanAmountRecord] = ets:lookup(customertable, CustomerName),
  RequiredLoanAmount = element(2, RequiredLoanAmountRecord),
  TargetBank = bank:getRandomBank(PotentialBanksList),
  TargetBankName = element(1, TargetBank),
  TargetBankId = whereis(TargetBankName),
  SleepDuration = rand:uniform(100),
  if
    RequiredLoanAmount >= 50 ->
      Amount = rand:uniform(50),
      timer:sleep(SleepDuration),
      TargetBankId ! {self(), {Customer, Amount, TargetBank}};
    true ->
      if
        RequiredLoanAmount =< 0 -> done;
        true ->
          AmountRand = rand:uniform(RequiredLoanAmount),
          timer:sleep(SleepDuration),
          TargetBankId ! {self(), {Customer, AmountRand, TargetBank}}
      end
  end,
  receive
    loanapproved ->
      if
        RequiredLoanAmount > 0 ->
          requestLoan(Customer, PotentialBanksList);
        true ->
          done
      end;
    loannotapproved ->
      NewPotentialBanksList = lists:delete(TargetBank, PotentialBanksList),
      LengthOfList = length(NewPotentialBanksList),
      if
        LengthOfList > 0 ->
          requestLoan(Customer, NewPotentialBanksList);
        true ->
          OriginalLoanObjective = element(2, Customer),
          TotalLoanApproved = OriginalLoanObjective - RequiredLoanAmount,
          MasterPid = whereis(master),
          MasterPid ! {didnotreachobjective, CustomerName, TotalLoanApproved}
%%          io:fwrite("~w was only able to borrow ~w dollar(s). Boo Hoo!~n", [CustomerName, TotalLoanApproved])
      end
  end.