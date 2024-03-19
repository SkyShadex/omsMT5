//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void strategyTesterEntry(bool control, bool single,int orderLimit)
  {
   if(!control || isDrawdown)
      return;

   string symbol = _Symbol;
   if(single)
     {
      mainlogic(symbol,orderLimit);
     }
   else
      for(int i=0; i<symbolListSize-1; i++)
        {
         mainlogic(symGood[i],orderLimit);
        }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void mainlogic(string const symbol,int orderLimit)
  {
   if(!IsMarketOpen(symbol))
      return;

   if(pa.CountPositions(symbol)>=orderLimit)
     {
      return;
     }

   int trigger = MathRand();
   bool trig = false;
   bool plat = MathRand() % 3 == 0 && MathRand() % 3 == 0 && MathRand() % 3 == 0;
   bool gold = MathRand() % 3 == 0 && MathRand() % 3 == 0;
   bool silver = MathRand() % 16 == 0 && MathRand() % 3 == 0;
   bool bronze = MathRand() % 16 == 0;

   int h = wScrambler;
   switch(h)
     {
      case 1:
         trig = plat;
         break;
      case 6:
         trig = gold;
         break;
      case 3:
         trig = silver;
         break;
      case 4:
         trig = bronze;
         break;
      case 5:
         trig = filters(symbol,40,60);
         break;
      case 2:
         trig = filters(symbol,30,70);
         break;
     }
   if(trig)
     {
      Print("TESTER",symbol);
      CSkySymbolInfo newOrderInfo(symbol);
      pushOrder("buy", 0, newOrderInfo);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool filters(string symbol,double min, double max)
  {
   int rsiValue = iRSI(symbol,stratTimeframe,18,PRICE_CLOSE);
   double rsiCurrent;
   if(rsiValue != INVALID_HANDLE)
     {
      double PriceArray[];
      ArraySetAsSeries(PriceArray, true);
      if(CopyBuffer(rsiValue, 0, 0, 10, PriceArray) == 10 && PriceArray[0] != EMPTY_VALUE)
        {
         rsiCurrent = NormalizeDouble(PriceArray[0], SymbolInfoInteger(symbol,SYMBOL_DIGITS));

         bool rsi = rsiCurrent > max || rsiCurrent < min;
         bool atrspread = atrCalc.SpreadRatio(1,symbol)>1;
         if(atrspread && rsi)
            return true;
        }
     }
   return false;
  }


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
