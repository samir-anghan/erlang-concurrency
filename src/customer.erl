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
-export([initCustomerProcess/1]).

initCustomerProcess(Customer) ->
  CustomerName = element(1, Customer),
  LoanObjective = element(2, Customer).

