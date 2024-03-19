//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+




double maxvolATR=0,minvolATR=10,normvolATR=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double volatilityATR(const string symbol)
  {
   GetIndicatorValues();
   if(symbol=="ALL")
     {
      int size = ArraySize(symGood);
      for(int i=size; i<=0; i--)
        {
         calc_volatilityATR(symGood[i]);
        }
      return -2;
     }
   else
      return calc_volatilityATR(symbol);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calc_volatilityATR(const string symbol)
  {
   double ATR_Current = calcATR(symbol);
   if(ATR_Current<=0.0)
      return -1;

   double mid = (SymbolInfoDouble(symbol,SYMBOL_ASK)+SymbolInfoDouble(symbol,SYMBOL_BID))/2;
   double volatilityRatio = ATR_Current/mid;
   volatilityDataCollect(symbol,volatilityRatio);

   return volatilityRatio;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


const int volArrayIndex = S_IND_ATRVol;
void volatilityDataCollect(const string symbol,const double volatilityATR)
  {
   int arrayID = ArrayContainsPosition(symbol,symGood);
   if(arrayID!=-1)
     {
      symbol_ind_vals[arrayID][volArrayIndex] = volatilityATR;
      if(symbol_ind_vals[arrayID][volArrayIndex+2]==0)
         symbol_ind_vals[arrayID][volArrayIndex+2]=volatilityATR;
      else
         if(volatilityATR>symbol_ind_vals[arrayID][volArrayIndex+2])
            symbol_ind_vals[arrayID][volArrayIndex+2]=(volatilityATR+symbol_ind_vals[arrayID][volArrayIndex+2])/2;
      if(symbol_ind_vals[arrayID][volArrayIndex+1]==0)
         symbol_ind_vals[arrayID][volArrayIndex+1]=volatilityATR;
      else
         if(volatilityATR<symbol_ind_vals[arrayID][volArrayIndex+1])
            symbol_ind_vals[arrayID][volArrayIndex+1]=(volatilityATR+symbol_ind_vals[arrayID][volArrayIndex+1])/2;
      maxvolATR = fmax(symbol_ind_vals[arrayID][volArrayIndex+2],maxvolATR);
      minvolATR = fmin(symbol_ind_vals[arrayID][volArrayIndex+1],minvolATR);

      double safetybuffer = 0.2;
      if(symbol_ind_vals[arrayID][volArrayIndex+2] != symbol_ind_vals[arrayID][volArrayIndex+1])
         symbol_ind_vals[arrayID][volArrayIndex+3] = (symbol_ind_vals[arrayID][volArrayIndex] - (symbol_ind_vals[arrayID][volArrayIndex+1]*(1-safetybuffer))) / ((symbol_ind_vals[arrayID][volArrayIndex+2]*(1+safetybuffer)) - (symbol_ind_vals[arrayID][volArrayIndex+1]*(1-safetybuffer)));
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
