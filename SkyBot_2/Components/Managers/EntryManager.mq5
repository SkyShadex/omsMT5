//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

sinput group "Entry Modifications"
sinput bool           PriceLagFlag = false;
sinput double         PriceInputLag = 0.25; // Entry Price Lag %
sinput bool           ladder_order = false; //Splits position into several orders spread over the price lag.
sinput int            ladder_split = 4;
sinput double         atrMultiplier_ScaleIn = 1; //Scale In ATR Factor
double                priceLag = PriceInputLag/100;
double                entryLag = 0.990;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void IsValidOrder(ParsePayload &tradeData)
  {
//Print(GetIndicatorHandles());
//Print(GetIndicatorValues());

   string symbol;
   string symbolPrefix = StringSubstr(tradeData.GetSymbol(), 0, 4);
   transcribePrefix(symbolPrefix);
   
   bool searchFail = true;
   for(int i = 0; i < ArraySize(symGood); i++)
     {
      if(StringFind(symGood[i],symbolPrefix)!=-1)
        {
         // Use the symGood array value instead of symbolTest
         symbolTest = symGood[i];
         symbol = symGood[i];
         searchFail = false;
         break;
        }
     }

   if(searchFail)
     {
      Print("no match: ",tradeData.GetSymbol());
      return;
     }

   int timeEST = int(TimeLocal()+(3600*4));
   if(tradeData.GetTimestamp() != previousDateTime && int(timeEST-tradeData.GetTimestamp())>2)
     {
      return;
     }

   if(tradeData.GetTimestamp() != previousDateTime)
     {
      GetIndicatorValues();
      previousDateTime = tradeData.GetTimestamp();
      GlobalVariableSet(GV_PREVDATE, previousDateTime);

      if(isDrawdown)
        {
         Print("<!!!! Error: Drawdown !!!!>");
         return;
        }

      if(marginLevel<250)
        {
         printf("<!!!! Error: Margin Limit Reached %.2f %s !!!!> ",marginLevel,symbol);
         return;
        }

      if(StringFind(tradeData.GetSide(), "buy") >= 0)
        {
         int timer = getOldestPositionInfo(symbol, POSITION_TYPE_BUY, "newest");
         bool timeCheck = timer<=45 && timer != 0; //PeriodSeconds(PERIOD_M30)
         bool countCheck = Pyramid*5<=pa.CountPositions(symbol);//ladder_order?ladder_split:Pyramid*2<=pa.CountPositions(symbol);
         if(timeCheck ||countCheck)
           {
            if(timeCheck)
               printf("<============= Error: %s lastest position %d minutes old =============> ",symbol,timer/60);
            if(countCheck)
               printf("<============= Error: Max Positions Reached! %s =============>",symbol);
            return;
           }
        }

      printf("%s: Side: %s Price: %.3f",symbol,tradeData.GetSide(),tradeData.GetPrice());
      CSkySymbolInfo newOrderInfo(symbolTest);
      pushOrder(tradeData.GetSide(), tradeData.GetPrice(), newOrderInfo);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void pushOrder(string side,const double price_signal, CSkySymbolInfo &symbolInfo)
  {
   string symbol = symbolInfo.symbol;

   if(StringFind(side, "sell") >= 0)
     {
      printf("<====== New Sell Order: %s ======>",symbol);
      if(!clientside_sellOrders)
         pa.CloseAllOrders(symbol);
      if(!clientside_sell)
         pa.CloseAllPositions(symbol);
      return;
     }

   if(!GetIndicatorValues())
      return;

   Print("");
   Print("");
   printf("<=========================== New Order: %s =====================================>",symbol);
   double ticksize = symbolInfo.ticksize;
   long digits = symbolInfo.symDigits;

   double newprice = NormalizeDouble(price_signal,digits);
   double ask = symbolInfo.ask;
   double bid = symbolInfo.bid;


//double slPoints = hedgeDistance(symbol);

   if(PriceLagFlag)
     {
      Print(__FUNCTION__+": Entry Price Lag:",(string)PriceLagFlag);
      double atrprice = NormalizeDouble(newprice-(atrCalc.StopLoss(1,symbol)*ticksize),digits);
      newprice = NormalizeDouble((newprice*(1-priceLag)),digits);
      newprice = MathMax(atrprice,newprice);
     }

   if(newprice>ask*1.05 || newprice<bid*0.95)
     {
      Print(__FUNCTION__+": Entry Protection Enabled");
      newprice = ask;
     }

   double sl=0,tp=0;
   if(!exitLevels(symbol,side,1,sl,tp) && !PriceLagFlag) // TODO: Why does this not work with PriceLagFlag??? //atrCalc.StopLoss(allocData.FindByAsset(symbol).tradingrange,symbol)
     {
      printf(__FUNCTION__+": INVALID STOPS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! %s",symbol);
      return;
     }


   sl = NormalizeDouble(sl,digits);
   tp = NormalizeDouble(tp,digits);

   if(debug)
      printf(__FUNCTION__+symbol," [Order Info]: Ask: %.2f | Bid: %.2f | Spread: %.2f ====================>",ask,bid,symbolInfo.spread);

   double slDistance = bid - sl;
   double tpDistance = tp - ask;
   double rrr = slDistance != 0 ? (tpDistance/slDistance) : 0;

   ps.refresh(symbol);
   double lots = ps.CalcLots(slDistance,symbol);


// Entry Decision Tree

   if(StringFind(side, "buy") >= 0)
     {
      if(debug)
        {
         printf(__FUNCTION__+": %s Here's your pretend order! (Debug Mode)",symbol);
         printf(__FUNCTION__+": %s [Order Payload]: New Price: %.2f | SL:  %.2f | TP:  %.2f | Lots:  %.2f ====================>",symbol,newprice,sl,tp,lots);
         return;
        }

      if(sl > newprice)
        {
         printf(__FUNCTION__+": SL Error Detected %s : %.2f",symbol,sl);
         sl=0;
         tp=0;
         //return;
        }

      if(Hedge_Enable)
        {
         HedgeEntry(newprice,symbol,tp,symbolInfo,rrr);
         return;
        }


      bool isDownTrend = allocData.FindByAsset(symbol).riskAdjustReturn<=-0.5;// && allocData.FindByAsset(symbol).dailyReturns<-1 && allocData.FindByAsset(symbol).covariance<0;
      Print("Placing Order... ", isDownTrend);
      entry_Manager(lots,newprice,symbol,NormalizeDouble(sl,digits),NormalizeDouble(tp,digits),slDistance,symbolInfo,isDownTrend);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void entry_Manager(double lots, double price, string symbol, double sl, double tp, double slDist, CSkySymbolInfo &symbolInfo, bool sentimentSignal)
  {
   double ticksize = symbolInfo.ticksize;
   long digits = symbolInfo.symDigits;

   if(debug)
     {
      Print(__FUNCTION__+": Here's your pretend order! (Debug Mode)");
      return;
     }

   if(clientside_freeup_order)
     {
      pa.CloseAllOrders(symbol); //clear pending orders
     }
   ulong ticket1;

   if(!ladder_order)
     {
      double scalar = normalizeFunc(allocData.FindByAsset(symbol).riskAdjustReturn,-10,0,allocData.FindByAsset(symbol).averageReturn,0,NULL);
      double price2 = NormalizeDouble(symbolInfo.bid*(1+(scalar)),symbolInfo.symDigits);
      correctStopLevel(symbol,ORDER_TYPE_BUY,price2,NULL,100,symbolInfo);
      double sl2 = NormalizeDouble(price2*entryLag,symbolInfo.symDigits);
      correctStopLevel(symbol,ORDER_TYPE_BUY,sl2,NULL,100,symbolInfo);
      if(!sentimentSignal)
        {
         if(!trade.Buy(lots,symbol,0,sl,tp,NULL))
           {
            errorRate+=10;
            printf(__FUNCTION__+": Order Failed %s",symbol);
            Print(price2," ",scalar);
            trade.BuyLimit(lots,price2,symbol,sl2,tp,ORDER_TIME_GTC,0,NULL);
            //ExpertRemove();
           }
        }
      else
        {
         Print(price2," ",scalar);
         trade.BuyLimit(lots,price2,symbol,sl2,tp,ORDER_TIME_GTC,0,NULL);
         //if(!trade.Sell(lots,symbol,0,tp,sl,NULL))
         //   errorRate++;
        }
      ticket1 = trade.ResultOrder();
      return;
     }
   else
     {
      double  laggingprice = NormalizeDouble(price-(atrCalc.StopLoss(atrMultiplier_ScaleIn,symbol)*ticksize),digits);
      double ladder_price_dist = (price-laggingprice)/ladder_split;

      double splitweight = 0.25;
      double lots_to_split = lots;
      double first_order_lots = lots * splitweight;
      first_order_lots =  ps.RoundLots(first_order_lots,symbol);

      lots_to_split = lots * (1-splitweight);

      double split_lots = NormalizeDouble(lots_to_split / ladder_split,digits);

      split_lots =  ps.RoundLots(split_lots,symbol);
      if(split_lots * ladder_split > lots * 1.05)
        {
         Print(__FUNCTION__,": Split Lots Exceed Original Lots. Override");
         // Place the first order
         trade.BuyLimit(lots, price, symbol, sl, tp, ORDER_TIME_DAY, 0, NULL);
         ticket1 = trade.ResultOrder();
        }
      else
        {
         if(PriceLagFlag)
           {
            expTime = TimeCurrent()+(3600*2);
            trade.BuyLimit(first_order_lots, price, symbol, sl, tp, ORDER_TIME_SPECIFIED, expTime, NULL);
           }
         else
           {
            trade.Buy(first_order_lots,symbol,0,sl,tp, NULL);
           }

         ticket1 = trade.ResultOrder();
         Print(__FUNCTION__,": Placing Ladder Orders...");
         // Place additional ladder orders
         for(int i = 1; i < ladder_split; i++)
           {
            expTime = TimeCurrent()+(60*30);
            double ladder_price = NormalizeDouble(price - (i * ladder_price_dist),digits);
            if(Hedge_Enable)
              {
               sl = 0;
              }
            else
              {
               sl = NormalizeDouble(ladder_price-slDist,digits);
              }
            trade.BuyLimit(split_lots, ladder_price, symbol, sl, tp, ORDER_TIME_SPECIFIED, expTime, NULL);
            ticket1 = trade.ResultOrder();
           }
        }
     }
   if(ticket1 > 0)
     {
      Print(__FUNCTION__,": Order Placed");
     }
  }

//+------------------------------------------------------------------+
