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
-export([initBankProcess/1]).

initBankProcess(Bank) ->
  BankName = element(1, Bank),
  FinancialResources = element(2, Bank).