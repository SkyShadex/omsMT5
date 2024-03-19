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
         // ATR value is not available, set a default stop loss value
         double backupATR = BiggestDayLoss(symbol);
         Print("ATR value is not available, using backup stop loss: ", backupATR, " pips");
         return BiggestDayLoss(symbol);
        }

      double stopLossDistance = ATR_Current * atrFactor;
      double sl_in_Pips = NormalizeDouble(stopLossDistance / s.symPoint, s.symDigits); // Convert to pips
      if(debug)
        {
         Print(__FUNCTION__, ": ", sl_in_Pips);
        }
      return sl_in_Pips;
     }

   double            SpreadRatio(double atrFactor, string symbol)
     {
      s.New(symbol);
      double currentATR = NormalizeDouble(calcATR(symbol) / s.ticksize, s.symDigits);
      if(currentATR<0)
         Print(__FUNCTION__,"ERROR <0");
      currentATR = currentATR * atrFactor;
      double atrspread = currentATR / s.spread;
      return atrspread;
     }
  };



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double            calcATR(string symbol)
  {
   CSkySymbolInfo s(symbol);
   int atrValue = iATR(symbol, PERIOD_M15, 14);
   if(atrValue != INVALID_HANDLE)
     {
      double PriceArray[];
      ArraySetAsSeries(PriceArray, true);
      if(CopyBuffer(atrValue, 0, 0, 3, PriceArray) == 3 && PriceArray[0] != EMPTY_VALUE)
        {
         double ATR_Current = NormalizeDouble(PriceArray[0], s.symDigits);
         if(debug)
            Print(__FUNCTION__, ": ", ATR_Current);
         IndicatorRelease(atrValue);
         return ATR_Current;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------+
