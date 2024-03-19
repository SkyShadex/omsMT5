//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+


string symMetals[] = {"XAUUSD","XAGUSD"}; //,"XAUAUD","XAUEUR","XPDUSD"
string symCurrencies[] = {"EURUSD","EURJPY","USDCHF","AUDJPY","AUDNZD","AUDUSD","AUDCAD","GBPUSD","GBPCHF","USDJPY","USDCAD","EURNZD","NZDUSD"};
string symCrypto[] = {"BTCUSD","ETHUSD"}; //"LTCUSD",
string symIndices[] = {"US30","DAX40","JPN225","NAS100","SP500","UK100"}; //"US100.cash","US500.cash","US2000.cash","JP225.cash","HK50.cash","EU50.cash","AUS200.cash","GER40.cash","FRA40.cash","SPN35.cash"
string symFutures[] = {"NATGAS.f"};
string symCommodity[] = {"USOIL.cash"};
string symStocks[] = {"NVDA"};
string symGood[];
int symbolListSize;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LoadValidSymbols()
  {
   ArrayCopy(symGood,symMetals,ArraySize(symGood));
   ArrayCopy(symGood,symCurrencies,ArraySize(symGood));
   ArrayCopy(symGood,symCrypto,ArraySize(symGood));
   ArrayCopy(symGood,symIndices,ArraySize(symGood));
//ArrayCopy(symGood,symFutures,ArraySize(symGood));
//ArrayCopy(symGood,symCommodity,ArraySize(symGood));
//ArrayCopy(symGood,symStocks,ArraySize(symGood));
   symbolListSize = ArraySize(symGood);
   Print(symbolListSize," Symbols Loaded...");
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void transcribePrefix(string &symbolPrefix)
  {
   if(symbolPrefix == "JP22"|| StringFind(symbolPrefix,"225")!=-1)
     {
      symbolPrefix="JPN225";
     }
   if(symbolPrefix == "GER4"|| StringFind(symbolPrefix,"GER4")!=-1)
     {
      symbolPrefix="DAX40";
     }
   if(symbolPrefix == "US10"|| StringFind(symbolPrefix,"US10")!=-1)
     {
      symbolPrefix="NAS100";
     }
   if(symbolPrefix == "US50"|| StringFind(symbolPrefix,"US50")!=-1)
     {
      symbolPrefix="SP500";
     }
//if(symbolPrefix == "ESP3"|| StringFind(symbolPrefix,"ESP")!=-1)
//  {
//   symbolPrefix="SPN35.cash";
//  }
  }

//+------------------------------------------------------------------+
