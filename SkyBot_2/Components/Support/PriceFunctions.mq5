//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsStopLevelValid(const string symbol,const int side,const double price,const string direction)
  {
   CSkySymbolInfo si;
   si.New(symbol);
   double ask = si.ask;
   double bid = si.bid;
   long StopLvl = si.stopsLevel;
   long Spread = si.spread;
   double symPoint = si.symPoint;
   double buffer = (double)Spread*2;
   double limitSL = (StopLvl - buffer) * symPoint;
   double limitTP = (StopLvl + buffer) * symPoint;
   double testSL = bid - price;
   double testTP =  price - ask;
   bool checkTP = testTP > limitTP;
   bool checkSL = testSL > limitSL;
   bool status = true;
   bool IsInsideSpread = checkSL && checkTP;
   bool IsInvalid = !checkSL && !checkTP;
//if(side == POSITION_TYPE_SELL)
//  {
//   if(checkSL && checkTP)
//     {
//      Print("Invalid Price. Buy Side: ",checkSL," < ",limitSL," : ",StopLvl," ",Spread);
//      //hedgePrice=ask+(MathMin(atrCalc.StopLoss(atrFactor,symbol),100)*si.ticksize);
//      return false;
//     }
//  }
//if(side == POSITION_TYPE_BUY)
//  {
   if(IsInsideSpread || IsInvalid)
     {
      if(IsInsideSpread)
         printf("Invalid Stop. Inside 2 Stop Levels.");
      printf("Lower Stop | Limit : .6f% < .6f% . Stop level: .2f% . Spread: .2f%",testSL,limitSL,StopLvl,Spread);
      printf("Upper Stop | Limit : .6f% < .6f% . Stop level: .2f% . Spread: .2f%",testTP,limitSL,StopLvl,Spread);
      errorRate++;
      status = false;
     }

   return status;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool exitLevels(const string symbol,const int side,double tradingrange,double& sl, double& tp)
  {
   CSkySymbolInfo si;
   CAllocationData* data = allocData.FindByAsset(symbol);
   si.New(symbol);
   double tpPercentage=0,slPercentage=0;

   if(tradingrange<=0)
     {
      errorRate++;
      //return false;
     }
// Define the percentage of the trading range for TP and SL
   slPercentage = ScalarMacro(symbol,1,data.slPercentage,ww2,"increase","inv");  // 50% of the trading range symbolOpt(symbol,2)
//double minSL,maxSL;
   if(slPercentage <= 0.1 || slPercentage >=0.8)
     {
      errorRate++;
      slPercentage = fmin(fmax(0.1,slPercentage),0.8);
      //return false;
     }

   tpPercentage = 1-slPercentage; // split the trading range for tp based on sl

   if(slPercentage+tpPercentage!=1) // check that we haven't exceed 100%
     {
      errorRate++;
      //return false;
     }

// Calculate TP and SL levels
   double priceLag = si.bid*entryLag;//IndData(symbol,S_IND_MA);
   //double maPrice = IndData(symbol,S_IND_MA);
   double modifier = priceLag;
   double spread = (si.spread*10)*si.ticksize;

   if(modifier>si.ask)
      tradingrange = MathAbs(modifier-si.bid)+spread;
   else
      if(modifier<si.bid)
         tradingrange = MathAbs(modifier-si.ask)+spread;
      else
         tradingrange = MathAbs(modifier-((si.ask+si.bid)/2))+spread;

   double slDist = tradingrange*0.2; //slPercentage * tradingrange;
   double tpDist = tradingrange*0.8; //tpPercentage * tradingrange;

   if(side == POSITION_TYPE_BUY)
     {
      sl = si.bid - slDist;
      tp = si.ask + tpDist;
     }
   else
     {
      tp = si.bid - slDist;
      sl = si.ask + tpDist;
     }

   if(!IsStopLevelValid(symbol,side,sl,"down")||!IsStopLevelValid(symbol,side,tp,"up"))
     {
      errorRate++;
      return false;
     }

   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void correctStopLevel(const string symbol,const int side,double& price,const string mode,const int attempts,CSkySymbolInfo &si)
  {
// Check for valid stop level
   int k = 1;
   while(k<attempts && !IsStopLevelValid(symbol, side, price, mode))
     {
      price = price - ((k * si.spread+1)*si.ticksize);
      k++;
      errorRate++;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool correctPositionSize(const string symbol,const int side,const double entryPrice,double& lots,const int attempts)
  {
   double trigger = 0;
   double acctBal = accountBalance("balance");
   if(!OrderCalcMargin(ORDER_TYPE_BUY,symbol,lots,entryPrice,trigger))
      return false;
   double result = trigger/acctBal;
   double limit = 0.1;
   bool test = result > limit;
   bool status = true;
   if(test)
     {
      Print(__FUNCTION__,trigger," ",result);
      status = false;
     }

   int k = 1;
   while(k<attempts && result >= limit)
     {
      lots = ps.RoundLots(lots*0.6,symbol);
      if(OrderCalcMargin(ORDER_TYPE_BUY,symbol,lots,entryPrice,trigger))
         result = trigger/acctBal;
      k++;
      errorRate++;
     }

   return status;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
