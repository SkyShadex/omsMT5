//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

struct PositionData
  {
   string            Sym;
   ulong             ticket;
   double            TickSize;
   long              digits;
   double            Ask;
   double            Bid;
   long              StopLvl;
   long              Spread;
   double            OpenPrice;
   double            CurrentPrice;
   double            PriceDeltaPercent;
   double            Profit;
   double            TP;
   double            SL;
   double            Lots;
   long              Age;
   double            oldestAge;
   double            minAge;
   double            SpreadRatio;
   int               countOrders;
   int               countPositions;
   bool              isHedgeInside;
   double            netSymbolProfit;
   double            netProfitPercent;
   double            hedge_TargetPercent;
   double            sentimentSignal;
   ENUM_POSITION_TYPE Side;
  };

//+------------------------------------------------------------------+
