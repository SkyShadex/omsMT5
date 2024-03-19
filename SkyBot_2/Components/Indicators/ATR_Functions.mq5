//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CATRCalculator
  {
private:
   CSkySymbolInfo       s;

public:
                     CATRCalculator()
     {
      // Constructor
     }



   double            StopLoss(double atrFactor, string symbol)
     {
      s.New(symbol);
      double ATR_Current = calcATR(symbol);

      if(ATR_Current <= 0.0)
        {
         return -1000;
         // ATR value is not available, set a default stop loss value
         double backupATR = BiggestDayLoss(symbol);
         Print("ATR value is not available, using backup stop loss: ", backupATR, " pips");
         return BiggestDayLoss(symbol);
        }

      double stopLossDistance = ATR_Current * atrFactor;
      double sl_in_Pips = NormalizeDouble(stopLossDistance * s.deltaPerLot, s.symDigits); // Convert to pips
      if(debug)
        {
         Print(__FUNCTION__, ": ", sl_in_Pips);
        }
      return sl_in_Pips;
     }

   double            SpreadRatio(double atrFactor, string symbol)
     {
      s.New(symbol);
      double currentATR = NormalizeDouble(calcATR(symbol) * s.deltaPerLot, s.symDigits);
      if(currentATR<0)
        {
         Print(__FUNCTION__,"ERROR <0");
         return -1;
        }
      currentATR = currentATR * atrFactor;
      double atrspread = currentATR / s.spread;
      return atrspread;
     }
  };



//+------------------------------------------------------------------+
//|                          DEPRECATE                               |
//+------------------------------------------------------------------+
double BiggestDayLoss(const string symbol)
  {
   datetime now = TimeCurrent();
   int daysBack = 10;
   datetime oneYearAgo = now - daysBack * 24 * 60 * 60;  // 365 days ago

   double largestRedCandlePips = 0;

   for(datetime time = now; time >= oneYearAgo; time -= PeriodSeconds(PERIOD_D1))
     {
      int barIndex = iBarShift(symbol, PERIOD_D1, time, true);
      double openPrice = iOpen(symbol, PERIOD_D1, barIndex);
      double closePrice = iClose(symbol, PERIOD_D1, barIndex);
      double priceChangePips = (openPrice - closePrice) / SymbolInfoDouble(symbol,SYMBOL_POINT);
      // Check if the candle is bearish (red)
      if(priceChangePips > largestRedCandlePips)
        {
         largestRedCandlePips = priceChangePips;
        }
     }
   double LossInPips = NormalizeDouble(largestRedCandlePips*atrMultiplier/2,SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   if(debug)
      Print(__FUNCTION__,": ",LossInPips);

   return LossInPips;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double            calcATR(string symbol)
  {
   double ATR_Current = IndData(symbol,0);
   if(ATR_Current>0)
      return ATR_Current;

   errorRate++;
   int atrValue = iATR(symbol, stratTimeframe, 14);
   if(atrValue != INVALID_HANDLE)
     {
      double PriceArray[];
      ArraySetAsSeries(PriceArray, true);
      if(CopyBuffer(atrValue, 0, 0, 1, PriceArray) == 1 && PriceArray[0] != EMPTY_VALUE)
        {
         atrValue = PriceArray[0];
         if(debug)
            Print(__FUNCTION__, ": ", ATR_Current);
         IndicatorRelease(atrValue);
        }
     }
   Print(__FUNCTION__," Indicator Error");
   return -1;
  }



//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
