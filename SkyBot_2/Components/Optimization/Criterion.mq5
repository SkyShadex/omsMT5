//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+



int errorRate = 1;
double lowerLimit = -30;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Criteria_1()
  {
   double errors = errorRate!=0?1/errorRate:0;
   double balance = TesterStatistics(STAT_PROFIT);

//if(balance>0)
//   errorRate=errorRate;
//else
//   errorRate=(errorRate-200)/4;
//return errorRate;

   double  min_dd = TesterStatistics(STAT_BALANCE_DD);
   if(min_dd > 0.0)
     {
      min_dd = 1.0 / min_dd;
     }

   double trades_number = TesterStatistics(STAT_TRADES);
   double trade_time = GetAverageOpenTime();
   double sharpe = TesterStatistics(STAT_SHARPE_RATIO);
   double ddp1 = fmax(TesterStatistics(STAT_EQUITYDD_PERCENT),TesterStatistics(STAT_EQUITY_DDREL_PERCENT));
   double ddp2 = fmax(TesterStatistics(STAT_BALANCEDD_PERCENT),TesterStatistics(STAT_BALANCE_DDREL_PERCENT));
   double ddp = fmax(ddp1,ddp2);
   double maxprofit = TesterStatistics(STAT_MAX_PROFITTRADE);


   double expectancy = TesterStatistics(STAT_EXPECTED_PAYOFF);
//return fmax((MathAbs(balance)*trades_number)*sharpe/100,-1000);
   double pf = TesterStatistics(STAT_PROFIT_FACTOR);
   double margin = TesterStatistics(STAT_MIN_MARGINLEVEL);
   double ptac = TesterStatistics(STAT_PROFITTRADES_AVGCON);


   if(trades_number==0)
      return(0);

   if(balance<0)
      return(-1);
   else
      if(trades_number<30)
         return(0.1);

   if(pf==0 || balance == 0)
      return(0);

   if(ddp>10)
      return(1);



//if(ddp > 5)
//   return(0);

   double lossratio = TesterStatistics(STAT_MAX_LOSSTRADE)/balance; // error if divide by 0
   double res = 0;
   int months = 9;
   int max = 20;
   double balanceNorm = normalizeFunc(balance,-5000,5000,1,max,NULL);
   double sharpeNorm = normalizeFunc(sharpe,-5,30,1,max,NULL);
   double minddNorm = normalizeFunc(ddp,1,7,1,max,"inv");
   double trades_numberNorm = normalizeFunc(trades_number,0,400,1,max,NULL);
   double profitshareNorm = normalizeFunc(maxprofit/balance,0,1,1,max,"inv");
   double lossshareNorm = normalizeFunc(MathAbs(lossratio),0,1,1,max,"inv");
   double expectancyNorm = normalizeFunc(expectancy,0,70,1,max,NULL);
   double marginNorm = normalizeFunc(margin,100000,200000,1,max,"inv");
   double sharpe2trade = normalizeFunc((sharpe/2)*trades_number,0,20000,1,max,NULL);
   double errorNorm = normalizeFunc(errorRate,0,10000,-180,0,"inv");
//if(trades_number<300)
//   trades_numberNorm = normalizeFunc(trades_number,1,100,0,20,NULL);
//else
//   trades_numberNorm = normalizeFunc(trades_number,100,1000,15,20,"inv");
//double pos_AvgTime = GetAverageOpenTime();
//if(pos_AvgTime<3600*3)
//   pos_AvgTime = normalizeFunc(pos_AvgTime,1,3600*3,0,20,NULL);
//else
//   pos_AvgTime = normalizeFunc(pos_AvgTime,3600*3,3600*24,0,20,"inv");

   res = balanceNorm+sharpeNorm+trades_numberNorm+profitshareNorm+lossshareNorm+expectancyNorm+minddNorm+marginNorm+sharpe2trade+errorNorm;
   res = res/9;

//   res = res*errors;
//   if(balance<0)
//      res = res/10;
//else
//   if(balance<100)
//      res = res/1.5;
//   else
//      if(balance<500)
//         res = res/1.25;
//      else
//         if(balance>1000)
//            res = res*1.25;



   if(errorRate==1)
      res = res*2;

//res = normalizeFunc(res,-1000,20000,0,10,NULL);
   return res;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAverageOpenTime()
  {
   if(HistorySelect(0,TimeCurrent()))
     {
      int totalOrders = HistoryOrdersTotal();
      int totalOpenTimeSeconds = 0;
      int failed = 0;
      ulong ticket;

      for(int i = 0; i < totalOrders; i++)
        {
         if((ticket = HistoryOrderGetTicket(i))>0)
           {
            int openTime = HistoryOrderGetInteger(ticket,ORDER_TIME_SETUP);
            int closeTime = MathMax(HistoryOrderGetInteger(ticket,ORDER_TIME_DONE),openTime+1);
            if(closeTime != 0)  // Check if the order is closed
              {
               double openTimeSeconds = closeTime - openTime;
               totalOpenTimeSeconds += openTimeSeconds;
              }
           }
        }
      if(totalOrders > 0)
        {
         double averageOpenTimeSeconds = totalOpenTimeSeconds / totalOrders;
         return averageOpenTimeSeconds; // Return the average open time in minutes
        }
      else
        {
         return 0; // No previous orders to calculate the average open time
        }
     }
   return 0;
  }




//   double param3 = (MathAbs(balance)*ptac)/balance;
//   param3 = param3/trades_number;
//   param3 = param3*1000;
//
//   if(param3<0)
//      return(-10);
//   param3 = MathLog(param3*balance);
//
//   if(param3>0 && balance<0)
//      param3 = param3>0?(param3/4):(param3*4);
//
//   if(balance > 0 && balance < 90 || pf>100)
//      param3 = param3>0?(param3/4):(param3*4);
//
//   if(param3>0 && sharpe<0.2)
//      param3 = param3>0?(param3/3):(param3*3);
//
//   if(param3>0 && balance<100)
//      param3 = param3>0?(param3/2):(param3*2);
//
//   param3 = MathMax(param3,-20);

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void backtestExit()
  {
   if(!backtest)
      return;

   bool toKill = false;

   if(AccountInfoDouble(ACCOUNT_EQUITY)<=StartingBalance*0.90)
      toKill = true;
        
   if(isDrawdown)
      toKill = true;   
      
   if(toKill)
        {
         pa.KillSwitch();
         Print("Null Hypothesis Confirmed: Test Fail");
         ExpertRemove();
        }
  }
//+------------------------------------------------------------------+
