//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

bool   OrderLock = false;
int    counterPM;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void positionManager()
  {
   if(isDrawdown)
      return;

   CSkySymbolInfo si(NULL);
   marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)!=0?AccountInfoDouble(ACCOUNT_MARGIN_LEVEL):StartingBalance;
   double acct_bal = accountBalance("balance");
   double minTP,maxTP;
   PositionData pos;
   pos.minAge =  5000; //normalizeFunc(MathLog(marginLevel),MathLog(500),MathLog(10000),(60*15),(60*15)*w22,NULL);
   string prev_sym;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         pos.Sym = PositionGetString(POSITION_SYMBOL);

         if(!IsMarketOpen(pos.Sym)) // Check for market open to avoid spam
           {
            if(debug)
               Print("Market Closed for ",pos.Sym,". Exiting function.");
            continue;
           }

         pos.OpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         pos.CurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         pos.Profit = PositionGetDouble(POSITION_PROFIT); //This is profit in USD.
         pos.TP =  PositionGetDouble(POSITION_TP);
         pos.SL = PositionGetDouble(POSITION_SL);
         pos.Lots = PositionGetDouble(POSITION_VOLUME);
         pos.Age = TimeCurrent()-PositionGetInteger(POSITION_TIME);
         pos.Side = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         pos.ticket = ticket;
         si.New(pos.Sym);

         pos.Ask = si.ask;
         pos.Bid = si.bid;
         pos.Spread = si.spread;
         pos.PriceDeltaPercent = NormalizeDouble(((pos.CurrentPrice/pos.OpenPrice)-1)*100,4);

         if(pos.Sym!=prev_sym)
           {
            prev_sym=pos.Sym;
            pos.TickSize = si.ticksize;
            pos.digits = si.symDigits;
            pos.StopLvl = si.stopsLevel;
            pos.netSymbolProfit = CalculateTotalProfit(pos.Sym);  // Inner Loop
            pos.netProfitPercent = NormalizeDouble(pos.netSymbolProfit/acct_bal,5);
            pos.countPositions = pa.CountPositions(pos.Sym); // Inner Loop
            pos.countOrders = pa.CountOrders(pos.Sym); // Inner Loop
            pos.SpreadRatio = 0;//atrCalc.SpreadRatio(atrMultiplier,pos.Sym);
            pos.oldestAge = MathMax(getOldestPositionInfo(pos.Sym, pos.Side, "age"), pos.Age); // Inner Loop
            pos.hedge_TargetPercent = 0.008;
            pos.sentimentSignal = 0.0;
            if(Hedge_Enable)
              {
               pos.sentimentSignal = sentimentScalar(pos.Sym,pos.oldestAge,pos.countPositions,marginLevel,1,1,1,"increase",NULL); // Inner Loop
               pos.hedge_TargetPercent = sentimentScalar(pos.Sym,pos.oldestAge,pos.countPositions,marginLevel,PositionAllocation(pos.Sym,Risk),1,1,"increase",NULL);
              } // Inner Loop
           }

         minTP=fmin(minTP,pos.hedge_TargetPercent);
         maxTP=fmax(maxTP,pos.hedge_TargetPercent); // /(pos.Age/1000)

         breakeven(true,pos);

         if(Hedge_Enable)
           {
            double buffer = 20 * pos.TickSize;//pos.Spread*normalizeFunc(pos.SpreadRatio,3.5,30,2,17.14,NULL)*pos.TickSize;
            pos.isHedgeInside = getOldestPositionInfo(pos.Sym,POSITION_TYPE_SELL,"last") + buffer > pos.CurrentPrice && pos.CurrentPrice > getOldestPositionInfo(pos.Sym,POSITION_TYPE_BUY,"last") - buffer; // Inner Loop

            //if(pos.SpreadRatio<1) // Check for Spread Sweeps
            //  {
            //   if(debug)
            //      Print("ATR/Spread Ratio Invalid",pos.Sym,". Exiting function.");
            //   continue;
            //  }


            //if(pos.isHedgeInside && pos.netSymbolProfit < 0 &&)
            //     {
            //      double trigger;
            //      OrderCalcMargin(ORDER_TYPE_BUY,pos.Sym,hedge_CalcImbalance(pos.Sym,"total"),pos.CurrentPrice,trigger);
            //      if(trigger/2/200000 > 0.16)
            //        {
            //         Print(trigger," ",trigger/2/200000);
            //         //toTrim = true;
            //        }
            //     }
            //<============================================================== Main Exit Logic ==============================================================>
            exitControlMain(false,pos);
            //<============================================================== Secondary Exit Logic ==============================================================>
            exitControlTime(false,pos);
            exitControlMargin(false,pos);
            hedgeProtection(false,pos);
            //<============================================================== Creating The Next Hedge Order ==============================================================>
            if(pos.SL == 0)
              {
               if(!PerformHedge(pos))
                  Print(__FUNCTION__,"Hedge Error");
              }
           }
         rogueOrderProtection(false,pos);
         exitControlMain(false,pos);
         exitControlTime(true,pos);
        }
     }
   string com = StringFormat("\nAvail. Capital: %.2f%$ | Min Target Profit: %.6f%% = %.2f%$ | Max Target Profit: %.6f%% = %.2f%$ | Min. Age: %.0f%mins | Signal %.4f",acct_bal,minTP,minTP*acct_bal,maxTP,maxTP*acct_bal, pos.minAge/60, pos.sentimentSignal);
   dataUI_Append(com);
//Print(pos.Sym,pos.netProfitPercent);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void breakeven(bool control,const PositionData &pos)
  {
   if(!control)// && (buycheck || sellcheck))
      return;

   if(pos.Side == POSITION_TYPE_BUY && pos.SL > pos.OpenPrice)
      return;

   if(pos.Side == POSITION_TYPE_SELL && pos.SL < pos.OpenPrice)
      return;

   double slDist = pos.OpenPrice-pos.SL;
   double symRAR = allocData.FindByAsset(pos.Sym).riskAdjustReturn;
   double threshold = normalizeFunc(symRAR,-10,10,0.075,w4,NULL);//.25; //0.4;
   bool buyBE = pos.PriceDeltaPercent > threshold && pos.Side == POSITION_TYPE_BUY;
   bool sellBE = pos.PriceDeltaPercent < -threshold && pos.Side == POSITION_TYPE_SELL;
   bool cashBE = pos.Profit>(normalizeFunc(symRAR,-10,1,w5/10,w5,NULL)*StartingBalance); //400;
   if(buyBE || sellBE || cashBE)
     {
      double sldGreed = MathAbs(pos.OpenPrice-pos.CurrentPrice)*0.4;
      double sldSafe = (20 * pos.TickSize);
      double slGreed = pos.Side == POSITION_TYPE_BUY?sldGreed+pos.OpenPrice:pos.OpenPrice-sldGreed;
      double slSafe = pos.Side == POSITION_TYPE_BUY?sldSafe+pos.OpenPrice:pos.OpenPrice-sldSafe;
      double slNew = NormalizeDouble(pos.Side == POSITION_TYPE_BUY?fmax(slSafe,slGreed):fmin(slSafe,slGreed), pos.digits);

      //// Check for valid stop level
      int k = 1;
      while(k<100 && !IsStopLevelValid(pos.Sym, pos.Side, slNew,NULL))
        {
         if(pos.Side == POSITION_TYPE_BUY)
            slNew = slNew - ((k * 100 * pos.TickSize));
         else
            slNew = slNew + ((k * 100 * pos.TickSize));
         k++;
        }

      if(trade.PositionModify(pos.ticket, slNew, pos.TP))
         printf("%s: Breakeven Detected. SL Adjustment. %d", pos.Sym, pos.Side);
     }
//else
//ExpertRemove();
  }


//+------------------------------------------------------------------+
//|        Catching unprotected orders. Mainly failed hedges.        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void hedgeProtection(bool control, const PositionData &pos)
  {

   if(!control)
      return;

   if(pos.countPositions>1 && pos.countOrders == 0 && pos.netSymbolProfit<-100 && !pos.isHedgeInside)
     {
      double pos_Price = getOldestPositionInfo(pos.Sym,pos.Side,"last");
      double Imbalance = hedge_CalcImbalance(pos.Sym,"percent");
      if(debug)
         Print(pos_Price," ",pos.Sym,": ",Imbalance);
      bool FailedSellStop = pos.Side == POSITION_TYPE_BUY && getOldestPositionInfo(pos.Sym,POSITION_TYPE_BUY,"last") > pos.CurrentPrice && Imbalance > 0;
      bool FailedBuyStop = pos.Side == POSITION_TYPE_SELL && getOldestPositionInfo(pos.Sym,POSITION_TYPE_SELL,"last") < pos.CurrentPrice && Imbalance < 0;
      bool FailSingle = (FailedBuyStop || FailedSellStop);
      bool FailandOrders = FailSingle && pos.countOrders == 0;
      if(FailSingle || FailandOrders)
        {
         OrderLock = true;
         Print(__FUNCTION__,": Failed Hedge. Attempting to correct. ",pos.Sym, " #",pos.ticket,". Age: ",pos.Age," P/L: ",pos.netSymbolProfit," ",Imbalance," ",pos_Price," ",FailedSellStop,FailedBuyStop,FailandOrders);
         pa.TrimAllPositions(pos.Sym,normalizeFunc(pos.netSymbolProfit,-600,-100,0.25,0.5,"inv"));
         trade.PositionModify(pos.ticket,0,0);
         OrderLock = false;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void exitControlMain(bool control, const PositionData &pos)
  {

   if(!control)
      return;

   if(pos.countOrders < 2)
      return;

   if(!OrderLock)
     {
      if(pos.netProfitPercent>=pos.hedge_TargetPercent)
        {
         //if(IsHedgeInside)
         //continue;
         OrderLock = true;
         Print("");
         Print("<=========================== Exit Condition Met =====================================>");
         int x;
         if(pos.netProfitPercent>=pos.hedge_TargetPercent && pos.hedge_TargetPercent>0.0)
            x = 3;
         else
            if(pos.netProfitPercent>=0)
               x = 1;
            else
               x = 2;

         switch(x)
           {
            case 1:
               Print(pos.Sym, ": Time Expiry: Breakeven. Close All. ", " P/L: ", pos.netSymbolProfit," Age: ",pos.Age/60,"mins.");
               break;
            case 2:
               Print(pos.Sym, ": Failed Trade. Close All. ", " P/L: ", pos.netSymbolProfit);
               break;
            case 3:
               Print(pos.Sym, ": Hedge Profit Target Reached. Close All.", " P/L: ", pos.netSymbolProfit);
               break;
           }

         // Close all positions & orders for a specific symbol
         for(int j = 2; j >= 0; j--)
           {
            pa.CloseAllPositions(pos.Sym);
            pa.CloseAllOrders(pos.Sym);
           }
         OrderLock = false;
         return;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void exitControlMargin(bool control,const PositionData &pos)
  {
   if(!control)
      return;

   if(pos.isHedgeInside || true)
     {
      if(!OrderLock && pos.countPositions > 1) // && pos.netSymbolProfit < -200
        {
         double trigger;
         OrderCalcMargin(ORDER_TYPE_BUY,pos.Sym,hedge_CalcImbalance(pos.Sym,"total"),pos.CurrentPrice,trigger);
         if(MathLog(trigger/2/200000)/pos.sentimentSignal > 35)
           {
            Print(trigger," ",trigger/2/200000);
            Print("<============= Margin Exit Condition Met =============>");
            printf(": Margin Expiration for %s. # %d. Age: %d. P/L: %.2f",pos.Sym,pos.ticket, pos.oldestAge, pos.netSymbolProfit);
            OrderLock = true;
              {
               double factor = 0.45; //normalizeFunc(pos.netSymbolProfit,lossLimit*4,0,0.4,0.8,"inv");
               pa.TrimAllPositions(pos.Sym,factor);
               //for(int j = 2; j >= 0; j--)
               //  {
               //   pa.CloseAllPositions(pos.Sym);
               //   pa.CloseAllOrders(pos.Sym);
               //  }
              }
            OrderLock = false;
            return;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void exitControlTime(bool control,const PositionData &pos)
  {
   if(!control)
      return;

   if(!Hedge_Enable)
      if(!OrderLock && pos.Age >= PeriodSeconds(PERIOD_D1)*4)
        {
         Print("<============= Time Exit Condition Met =============>");
         printf(": Time Expiration for %s. # %d. Age: %d. P/L: %.2f",pos.Sym,pos.ticket, pos.oldestAge, pos.netSymbolProfit);
         OrderLock = true;
         trade.PositionClose(pos.ticket);
         OrderLock = false;
         return;
        }
   if(!OrderLock && pos.netSymbolProfit < 0 && pos.countPositions > 1 && marginLevel < 5000)
     {
      int gap = 1;
      bool toTrim = false;
      int numberOfIterations = (int)MathCeil(pos.oldestAge / pos.minAge);
      for(int j = 0; j < numberOfIterations; j++)
        {
         double startTime = pos.minAge * j;
         double endTime = startTime + gap;
         if(pos.oldestAge > startTime && pos.oldestAge < endTime)
           {
            toTrim = true;
            break;  // Exit the loop if any condition is met
           }
        }

      //      bool isTrimmingTime = pos.sentimentSignal < 0.002;
      if(toTrim)
        {
         Print("<============= Time Exit Condition Met =============>");
         printf(": Time Expiration for %s. # %d. Age: %d. P/L: %.2f",pos.Sym,pos.ticket, pos.oldestAge, pos.netSymbolProfit);
         OrderLock = true;

         double factor = 0.4; //normalizeFunc(pos.netSymbolProfit,lossLimit*4,0,0.4,0.8,"inv");
         pa.TrimAllPositions(pos.Sym,factor);

         OrderLock = false;
         return;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void rogueOrderProtection(bool control,const PositionData &pos)
  {
   if(!control)
      return;
// Protecting Rogue Orders with stop losses
   if(pos.Side == POSITION_TYPE_BUY)
     {
      if(pos.SL == 0 && pos.Age > 60*10)
        {
         double rogue_SL;
         double rogue_SLD = ps.CalcSLDist(pos.Lots,pos.Sym);
         if(pos.CurrentPrice>pos.OpenPrice && pos.Profit > 0)
           {
            rogue_SL = NormalizeDouble(pos.CurrentPrice - rogue_SLD,pos.digits);
           }
         else
           {
            rogue_SL = NormalizeDouble(MathMin(pos.Bid*0.99995,pos.OpenPrice) - rogue_SLD,pos.digits);
           }
         double tp = pos.TP==0?NormalizeDouble(MathMax(pos.OpenPrice,pos.Bid) + (rogue_SLD*1.5),pos.digits):pos.TP;
         if(trade.PositionModify(pos.ticket,rogue_SL,tp))
           {
            Print(__FUNCTION__,": Human Trade Detected without SL. ",pos.Sym," $",rogue_SL);
           }
        }
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void trailingStop(bool control,const PositionData &pos)
  {
   if(!control || Hedge_Enable)
      return;

   double new_SL = pos.SL;
   if(pos.PriceDeltaPercent >= 0.2)
     {
      double increment_Percent = 0.04;
      // Calculate how many increments are needed based on the desired increment_Percent
      int incrementsNeeded = (int)(pos.PriceDeltaPercent / increment_Percent);
      // Ensure that the total incrementsNeeded are within a certain limit
      incrementsNeeded = MathMin(incrementsNeeded, 10); // Limit to a maximum of 10 increments
      // Calculate the new stop-loss price based on position side
      double new_SL_Price;
      double limit = 2;
      if(Hedge_Enable)
        {
         limit = limit;
        }
      double factor = ((incrementsNeeded - limit) * increment_Percent)/100;
      if(pos.Side == POSITION_TYPE_BUY)
        {
         new_SL_Price = pos.OpenPrice * (1+factor);
        }
      else
        {
         new_SL_Price = pos.OpenPrice *(1-factor);
        }

      new_SL = NormalizeDouble(new_SL_Price, pos.digits);
      //Print(__FUNCTION__," ",pos.Sym," ", pos_PriceDelta_Percent,"% ",incrementsNeeded, " ",factor, " ",new_SL_Price," ",new_SL, " ",pos.SL," ", pos.Side);
      if((pos.Side == POSITION_TYPE_BUY && new_SL > pos.SL && new_SL < pos.CurrentPrice) ||
         (pos.Side == POSITION_TYPE_SELL && new_SL < pos.SL && new_SL > pos.CurrentPrice))
        {
         if(trade.PositionModify(pos.ticket, new_SL, pos.TP))
           {
            if(pos.Side == POSITION_TYPE_BUY)
              {
               Print(__FUNCTION__, ": Protecting Profits. Adjusting Stops for Long Position. ", pos.Sym, " #", pos.ticket);
              }
            else
               if(pos.Side == POSITION_TYPE_SELL)
                 {
                  Print(__FUNCTION__, ": Protecting Profits. Adjusting Stops for Short Position. ", pos.Sym, " #", pos.ticket);
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+

