//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsMarketOpen(const string symbol)
  {
   datetime from = NULL;
   datetime to = NULL;
   datetime serverTime = TimeTradeServer();

// Get the day of the week
   MqlDateTime dt;
   TimeToStruct(serverTime,dt);
   const ENUM_DAY_OF_WEEK day_of_week = (ENUM_DAY_OF_WEEK) dt.day_of_week;

// Get the time component of the current datetime
   const int time = (int) MathMod(serverTime,3600*24);

   if(debug && false)
      PrintFormat("%s(%s): Checking %s", __FUNCTION__, symbol, EnumToString(day_of_week));

// Brokers split some symbols between multiple sessions.
// One broker splits forex between two sessions (Tues thru Thurs on different session).
// 2 sessions (0,1,2) should cover most cases.
   int session=2;
   while(session > -1)
     {
      if(SymbolInfoSessionTrade(symbol,day_of_week,session,from,to))
        {
         if(debug && false)
            PrintFormat("%s(%s): Checking %d>=%d && %d<=%d",
                        __FUNCTION__,
                        symbol,
                        time,
                        from,
                        time,
                        to);
         if(time >=from && time <= to)
           {
            if(debug&& false)
               PrintFormat("%s Market is open", __FUNCTION__);
            return true;
           }
        }
      session--;
     }
   if(debug&& false)
      PrintFormat("%s Market not open", __FUNCTION__);
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNightTime()
  {
   datetime localTime = TimeLocal();
   MqlDateTime int1;
   TimeToStruct(localTime,int1);
   int currentHour = int1.hour;
   int currentMinute = int1.min;
//Print(currentHour,":",currentMinute);

// Define the time ranges in hours and minutes
   int eveningStartHour = 18;   // 6:00 PM
   int eveningStartMinute = 0;
   int morningEndHour = 5;      // 6:00 AM
   int morningEndMinute = 0;

// Check if the current time is within the specified range
   bool NightTime = (currentHour >= eveningStartHour) || (currentHour <= morningEndHour);

   if(NightTime)
     {
      return true;
     }
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void serverClock()
  {
//--- time of the OnTimer() first call
   static datetime start_time=TimeCurrent();
//--- trade server time during the first OnTimer() call
   static datetime start_tradeserver_time=0;
//--- calculated trade server time
   static datetime calculated_server_time=0;
//--- local PC time
   datetime local_time=TimeLocal();
//--- current estimated trade server time
   datetime trade_server_time=TimeTradeServer();
//--- if a server time is unknown for some reason, exit ahead of time
   if(trade_server_time==0)
      return;
//--- if the initial trade server value is not set yet
   if(start_tradeserver_time==0)
     {
      start_tradeserver_time=trade_server_time;
      //--- set a calculated value of a trade server
      Print(trade_server_time);
      calculated_server_time=trade_server_time;
     }
   else
     {
      //--- increase time of the OnTimer() first call
      if(start_tradeserver_time!=0)
         calculated_server_time=calculated_server_time+1;;
     }
//---
   string com=StringFormat("Start time: %s\r\n",TimeToString(start_time,TIME_MINUTES|TIME_SECONDS));
   com=com+StringFormat("Local time: %s\r\n",TimeToString(local_time,TIME_MINUTES|TIME_SECONDS));
   com=com+StringFormat("TimeTradeServer time: %s\r\n",TimeToString(trade_server_time,TIME_MINUTES|TIME_SECONDS));
   com=com+StringFormat("EstimatedServer time: %s\r\n",TimeToString(calculated_server_time,TIME_MINUTES|TIME_SECONDS));
//--- display values of all counters on the chart
   Comment(com);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewDay()
  {
   int bars = iBars(_Symbol,PERIOD_D1);
   static int barsTotal = bars;
   if(barsTotal != bars)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
