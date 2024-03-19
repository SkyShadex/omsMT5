//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

//Hedge Function
sinput group "Zone Recovery Configuration"
sinput int            hedgePoints = 100;
sinput bool           Hedge_Enable = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HedgeEntry(const double price, const string symbol, const double tp, const CSkySymbolInfo &si, double sentimentSignal)
  {

   const double lots = ps.CalcLots(hedgeDistance(symbol),symbol);

   if(debug)
     {
      Print(__FUNCTION__, ": Here's your pretend order! (Debug Mode)");
      Print(__FUNCTION__,symbol," [Order Payload]: ","New Price: ",price,", SL: ",0," TP: ",tp,", Lots: ",lots,"====================>");
      return;
     }
   if(sentimentSignal<wDirectionBias)
     {
      if(trade.Buy(lots,symbol,0,0,tp,NULL))
         Print(__FUNCTION__,": Order Placed");
     }
   else
      if(trade.Sell(lots,symbol,0,0,NormalizeDouble(price-(tp - price),si.symDigits),NULL))
         Print(__FUNCTION__,": Order Placed");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double hedgeDistance(const string symbol) // TODO: Rename slDistDynamic
  {//Returns in points
   CSkySymbolInfo si(symbol);
   double normMargin = normalizeFunc(MathLog(marginLevel),MathLog(5000),MathLog(20000),0.53,1,NULL);
   double slDistance = atrCalc.StopLoss(allocData.FindByAsset(symbol).tradingrange,symbol)*normMargin; //0.075;
   return slDistance;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PerformHedge(const PositionData &pd)
  {
   if(!Hedge_Enable)
      return false;
   Print("<============= Hedging Active =============>");
   double HedgeReward = 0.6;
//HedgeReward = normalizeFunc(MathLog(marginLevel),MathLog(2500),MathLog(7500),HedgeReward,HedgeReward*2,"inv"); // fuzzy
   double slippage = normalizeFunc(MathLog(marginLevel),MathLog(500),MathLog(10000),1,1.15,NULL);
   double balanceFactor = NormalizeDouble(((HedgeReward+1)/HedgeReward)*slippage,3);
     {
      string com = StringFormat("\nBalance Factor: %.2f%", balanceFactor);
      dataUI_Append(com);
     }
   double countPositions = pd.countPositions;
   double hedgeLots = MathAbs(hedge_CalcLot(pd.Sym,pd.Side,balanceFactor));
   double LastPrice = getOldestPositionInfo(pd.Sym,pd.Side,NULL);
   const double x2 = hedgeDistance(pd.Sym);
   const double hedgeSLDist = (atrCalc.StopLoss(10, pd.Sym) * pd.TickSize) + (10 * pd.Spread * pd.TickSize);
   double Ask = SymbolInfoDouble(pd.Sym, SYMBOL_ASK);
   double Bid = SymbolInfoDouble(pd.Sym, SYMBOL_BID);
   double hedgePrice = pd.OpenPrice;
   const int numberOfOrders = (int)MathCeil(hedgeLots /  SymbolInfoDouble(pd.Sym, SYMBOL_VOLUME_MAX)); // Calculate the number of orders needed for oversize. Mostly yen pairs
   if(LastPrice > 0 && numberOfOrders <= 1)
      hedgePrice = NormalizeDouble(LastPrice, pd.digits);
   else
     {
      if(pd.Side == POSITION_TYPE_BUY)
         hedgePrice = NormalizeDouble(fmin(pd.OpenPrice,Bid) - x2, pd.digits);
      if(pd.Side == POSITION_TYPE_SELL)
         hedgePrice = NormalizeDouble(fmax(pd.OpenPrice,Ask) + x2, pd.digits);
     }

   if(pd.Side == POSITION_TYPE_BUY)
      hedgePrice = NormalizeDouble(hedgePrice + (countPositions * pd.Spread * 2 * pd.TickSize), pd.digits);
   else
      hedgePrice = NormalizeDouble(hedgePrice - (countPositions * pd.Spread * 2 * pd.TickSize), pd.digits);


// Check for valid stop level
   //int k = 1;
   //while(k<40 && !IsStopLevelValid(pd.Sym, pd.Side, hedgePrice,NULL))
   //  {
   //   hedgePrice = pd.Side == POSITION_TYPE_BUY ?
   //                hedgePrice - ((k * 200)*pd.TickSize):
   //                hedgePrice + ((k * 200)*pd.TickSize);
   //   k++;
   //  }


// Set stops
   double hedgeTP, hedgeSL;
   if(pd.Side == POSITION_TYPE_BUY)
     {
      hedgeTP = NormalizeDouble(hedgePrice - hedgeSLDist, pd.digits);
      hedgeSL = NormalizeDouble(hedgePrice + hedgeSLDist, pd.digits);
     }
   if(pd.Side == POSITION_TYPE_SELL)
     {
      hedgeTP = NormalizeDouble(hedgePrice + hedgeSLDist, pd.digits);
      hedgeSL = NormalizeDouble(hedgePrice - hedgeSLDist, pd.digits);
     }

// Place the hedge order
   Print(__FUNCTION__, ": Placing Hedge Order... ", pd.Sym, " $ ", hedgePrice);

// For over-max orders
   if(numberOfOrders > 1)
     {
      bool SplitsProduceOrders = false;
      hedgeLots = hedgeLots/numberOfOrders;
      Print(__FUNCTION__, " Splitting Order, Max Lots Protection: ",pd.Sym,": ", numberOfOrders," orders.");
      //if(numberOfOrders > 1)
      //SplitsProduceOrders = false;

      hedgeLots = ps.RoundLots(hedgeLots,pd.Sym);
      double singleOrderLots = ps.RoundLots(hedgeLots, pd.Sym);
      for(int i = numberOfOrders - 1; i >= 1; i--)
        {
         double priceMod = MathMin(pow(pd.Spread,countPositions),pd.CurrentPrice*1.05) * i * pd.TickSize;
         double slMod = atrCalc.StopLoss(10,pd.Sym)*pd.TickSize;
         if(pd.Side == POSITION_TYPE_BUY)
           {
            double splitPrice = hedgePrice - priceMod;
            double hedgeSplitSL = SplitsProduceOrders ? 0 : hedgePrice + slMod;
            if(!trade.SellStop(singleOrderLots,splitPrice,pd.Sym,hedgeSplitSL,hedgeTP,ORDER_TIME_GTC,"sell"))
              {
               Print("Split Order Error");
               return false;
              }
           }
         if(pd.Side == POSITION_TYPE_SELL)
           {
            double splitPrice = hedgePrice + priceMod;
            double hedgeSplitSL = SplitsProduceOrders ? 0 : hedgePrice - slMod;
            if(!trade.BuyStop(singleOrderLots,splitPrice,pd.Sym,hedgeSplitSL,hedgeTP,ORDER_TIME_GTC,"buy"))
              {
               Print("Split Order Error");
               return false;
              }
           }
        }
     }
   hedgeLots = ps.RoundLots(hedgeLots,pd.Sym);
// Place the hedge order based on the pos_Side
   if(pd.Side == POSITION_TYPE_BUY)
     {
      if(trade.SellStop(hedgeLots, hedgePrice, pd.Sym, 0, hedgeTP, ORDER_TIME_GTC, "sell"))
        {
         Print(__FUNCTION__, ": Sell Stop Order Placed");
         if(trade.PositionModify(pd.ticket, hedgeTP, NULL))
           {
            if(debug)
               Print(__FUNCTION__, ": Adjusting Stops for previous order. ", pd.Sym, " $", hedgeTP);
           }
         else
           {
            Print("FAILED",hedgePrice," ",hedgeTP);
           }
         return true;
        }
      else
         return false;
     }
   if(pd.Side == POSITION_TYPE_SELL)
     {
      if(trade.BuyStop(hedgeLots, hedgePrice, pd.Sym, 0, hedgeTP, ORDER_TIME_GTC, "buy"))
        {
         Print(__FUNCTION__, ": Buy Stop Order Placed");
         if(trade.PositionModify(pd.ticket, hedgeTP, NULL))
           {
            if(debug)
               Print(__FUNCTION__, ": Adjusting Stops for previous order. ", pd.Sym, " $", hedgeTP);
           }
         else
           {
            Print("FAILED",hedgePrice," ",hedgeTP);
           }
         return true;
        }
      else
         return false;
     }
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SpreadProtection(string symbol, string &arr[][])
  {

   CSkySymbolInfo s(symbol);
   double ticksize = s.ticksize;
   long symDigits = s.symDigits;
   double atrSpread = atrCalc.SpreadRatio(atrMultiplier, symbol);
   double currentATR = NormalizeDouble(calcATR(symbol) / ticksize, symDigits);
   currentATR = currentATR * atrMultiplier;

   double lowerBound = -1; // Default lower bound
   double upperBound = -1; // Default upper bound
   double atrLimitLog = 3;
   for(int i = 0; i < ArraySize(arr); i++)
     {
      if(arr[i][0] == symbol)
        {
         if(arr[i][3] > 0)
           {
            lowerBound = arr[i][3];
           }
         if(arr[i][4] > 0)
           {
            upperBound = arr[i][4];
           }
         if(arr[i][2] > 0)
           {
            atrLimitLog = arr[i][2]; // In Log
           }

         break;
        }
     }

   if(MathLog(atrSpread) >= atrLimitLog)
     {
      Print(symbol, " Spread: ", (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD), " ATR: ", currentATR, " Ratio: ", atrSpread, " LOG: ", MathLog(atrSpread));
      return true;
     }

   return false;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double hedge_LotSize(string symbol, int side)
  {
   double totalVolume = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         string pos_Sym = PositionGetString(POSITION_SYMBOL);
         double pos_Lots = PositionGetDouble(POSITION_VOLUME);
         ENUM_POSITION_TYPE pos_Side = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         if(pos_Sym == symbol && pos_Side == POSITION_TYPE_SELL && side == pos_Side)
           {
            totalVolume += pos_Lots;
           }

         if(pos_Sym == symbol && pos_Side == POSITION_TYPE_BUY && side == pos_Side)
           {
            totalVolume += pos_Lots;
           }
        }
     }

//totalVolume = roundLots(totalVolume,symbol); // DEPRECATE made calculations incorrect.
   if(totalVolume>0 && debug)
     {
      Print(__FUNCTION__,": Total Volume for ",symbol," : ",totalVolume);
     }
   return totalVolume;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double hedge_CalcLot(string symbol, int side, double factor)
  {
   double buyLots = MathAbs(hedge_LotSize(symbol,POSITION_TYPE_BUY));
   double sellLots = MathAbs(hedge_LotSize(symbol,POSITION_TYPE_SELL));
   double buyLotsFactored = (factor*buyLots);
   double sellLotsFactored = (factor*sellLots);
   double buyReturn = sellLotsFactored-MathAbs(buyLots);
   double sellReturn = buyLotsFactored-MathAbs(sellLots);
   if(debug)
     {
      Print(__FUNCTION__,": ", buyLots," ",sellLots," ",sellLotsFactored," ",buyReturn," ",side);
      Print(__FUNCTION__,": ", buyLots," ",sellLots," ",buyLotsFactored," ",sellReturn," ",side);
     }
   if(sellLotsFactored == 0)
     {
      buyReturn = buyLotsFactored;
     }
   if(buyLotsFactored == 0)
     {
      sellReturn = sellLotsFactored;
     }

   double payload;
   if(side==POSITION_TYPE_BUY)
     {
      payload = sellReturn;
      Print(__FUNCTION__,": Total Volume for Next Sell ",symbol," : ",payload);
     }
   if(side==POSITION_TYPE_SELL)
     {
      payload = buyReturn;
      Print(__FUNCTION__,": Total Volume for Next Buy ",symbol," : ",payload);
     }
   return payload;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double hedge_CalcImbalance(string symbol, string mode)
  {
   double buyLots = hedge_LotSize(symbol,POSITION_TYPE_BUY);
   double sellLots = hedge_LotSize(symbol,POSITION_TYPE_SELL);
   if(debug)
     {
      Print(symbol," ",buyLots);
      Print(symbol," ",sellLots);
     }
   double hedge_ImbalancePercent = NormalizeDouble(buyLots-sellLots/buyLots+sellLots,2)*100;
   if(mode == "total")
      return buyLots+sellLots;
   return buyLots-sellLots;
  }
//+------------------------------------------------------------------+
