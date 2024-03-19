//+------------------------------------------------------------------+
//|                                                    SkyBot_2.mq5  |
//|                                                        SkyShadex |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Indicators\Indicators.mqh>
#include <Math\Stat\Normal.mqh>
#include <Math\Alglib\alglib.mqh>
#include <Math\Alglib\matrix.mqh>

#include "\Components\Symbols.mq5"
#include "\Components\Class_Symbol_Info.mq5"
#include "\Components\Structures.mq5"
#include "\Components\Optimization\OptimizeWeights.mq5"
#include "\Components\Support\DrawdownProtection.mq5"
#include "\Components\Optimization\Criterion.mq5"
#include "\Components\Support\Time_Functions.mq5"
#include "\Components\Support\HelperFunctions.mq5"
#include "\Components\Support\PortfolioFunctions.mq5"
#include "\Components\Support\PriceFunctions.mq5"
#include "\Components\Support\Position_Size_Functions.mq5"
#include "\Components\Managers\RiskManager.mq5"
#include "\Components\Strategy\Hedging.mq5"
#include "\Components\Managers\PositionManager.mq5"
#include "\Components\Managers\EntryManager.mq5"
#include "\Components\Strategy\Tester.mq5"
#include "\Components\Networking.mq5"
#include "\Components\Indicators\ATR_Functions.mq5"
#include "\Components\Indicators\Indicators.mq5"
#include "\Components\Indicators\Volatility\Volatility_Funcs.mq5"
#include "\Components\ML\DecisionTree.mq5"



#property script_show_inputs


CTrade trade;
CDealInfo deal;
CPortfolioAssist pa;
CATRCalculator atrCalc;
CPositionSizeCalculator ps;
CBaseStat cstat;
CAlglib ml;

sinput group "Debugging"
sinput bool    debug = false;
bool           backtest = true;


// Other stuff
double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)!=0?AccountInfoDouble(ACCOUNT_MARGIN_LEVEL):StartingBalance;
input ENUM_TIMEFRAMES   stratTimeframe = PERIOD_H3;
datetime       previousDateTime = 0;
double         upperLine, lowerLine, equityMax;
double         downbad = 0;
double         slPips = 0;
datetime       expTime; // kill orders after certain time


string symbolTest = _Symbol;

// Combine the arrays into symGood


//int atrValue;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  OnTesterInit()
  {
   EventSetTimer(1);
   backtest = true;
   Optimize();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double result = Criteria_1();
   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
   shutdownSequence();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   LoadValidSymbols();
   bool result1 = GetIndicatorHandles();

   if(MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE))
     {
      Print("TESTING");
      backtest = true;
     }

   if(!backtest)
      EventSetMillisecondTimer(200);

   OrderLock = false;
   MathSrand(GetTickCount());

   Pyramid = (int)MathCeil(normalizeFunc(Risk,0.0001,10,1,MathFloor(200/symbolListSize),"inv")); // Max 200 orders. Pyramid Set to Risk.
   printf("Number of Orders Allowed Per Symbol: %d",Pyramid);
   Print("Handles Loaded: ",result1);
   if(!result1)
     {
      shutdownSequence();
      return(INIT_FAILED);
     }

   bool result2 = GetIndicatorValues();

   initArrs();
   CalculateKellyCrit("ALL");
   for(int i=allocData.Total()-1; i>=0; i--)
     {
      marginEqualizer(allocData[i].asset);
      allocData[i].risk = CalculateKellyCrit(allocData[i].asset);
     }
   NormalizeDPL(0,1);
   CalculateBetaWeights();

   ReportStats();
   Print("<========== Welcome ==========>");
   noDebugOrders();
//trainDF();
//for(int i = 0; i < skyrep.GetInnerObj().m_varimportances.Size(); i++)
//  {
//   printf("Element %d : %f", i, skyrep.GetInnerObj().m_varimportances.ToVector()[i]);
//  }

   return(INIT_SUCCEEDED);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   shutdownSequence();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//void OnTimer()
//  {
//   checkIndicators();
//   dataUI();
//   drawdownSafety(true);
//   socketSystem(true);
//   positionManager();
//  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   backtestExit();
   if(!backtest)
      return;
//   dataUI();
   positionManager();
   drawdownSafety(true);
   if(MathRand() % 4 == 0)
      strategyTesterEntry(true,false,Pyramid);
  }

double openPNL;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTrade()
  {
   if(!GetIndicatorValues())
     {
      Sleep(1000);
      GetIndicatorValues();
     }
   volatilityATR("ALL");
   CalculateBetaWeights();
   double variance = CalculateStats(false);
//int size = ArraySize(variancess);
//ArrayResize(variancess, size + 1);
//variancess[size] = variance;
   openPNL = MathLog(AccountInfoDouble(ACCOUNT_EQUITY)/AccountInfoDouble(ACCOUNT_BALANCE));
   double threshold = w6;
   if(openPNL > threshold)
     {
      //RebalancePortfolio("all");
      Print("KILL: ",variance," ",openPNL);
      pa.KillSwitch();
     }
//if(tradeHist.Size()>600)
//   if(!initTrain)
//      trainDF();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void shutdownSequence()
  {
   EventKillTimer();
   ReportStats();
   Print("Errors Detected: ",errorRate);
   deintHandles();
   allocData.Clear();
   allocData.Shutdown();
  }
//+------------------------------------------------------------------+


struct OrderData
  {
   long              positionID;
   string            sym;
   double            entryprice;
   double            sl;
   double            tp;
   double            RAR;
   double            DailyReturn;
   double            ind1;
   double            ind2;
   double            ind3;
   double            ind4;
   double            profit;
  };

OrderData tradeHist[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//void OnTradeTransaction(const MqlTradeTransaction &trans,
//                        const MqlTradeRequest &request,
//                        const MqlTradeResult &result)
//  {
////--- get transaction type as enumeration value
//   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
////--- if transaction is result of addition of the transaction in history
//   if(type==TRADE_TRANSACTION_DEAL_ADD)
//     {
//      ResetLastError();
//      if(HistoryDealSelect(trans.deal))
//         deal.Ticket(trans.deal);
//      else
//        {
//         Print(__FILE__," ",__FUNCTION__,", ERROR: ","HistoryDealSelect(",trans.deal,") error: ",GetLastError());
//         return;
//        }
//      if(deal.DealType()==DEAL_TYPE_BUY || deal.DealType()==DEAL_TYPE_SELL)
//        {
//         if(deal.Entry()==DEAL_ENTRY_IN)
//           {
//            // This is an "in" deal
//            // Process or store information as needed
//            ProcessInDeal(deal);
//            //Print("IN Deal: Ticket=", deal.Ticket(), ", Symbol=", deal.Symbol(), ", Price=", deal.Price());
//           }
//         else
//            if(deal.Entry()==DEAL_ENTRY_OUT)
//              {
//               ProcessOutDeal(deal);
//               //Print("OUT Deal: Ticket=", deal.Ticket(), ", Symbol=", deal.Symbol(), ", Price=", deal.Price());
//              }
//        }
//     }
//  }
//
//// Function to process "in" deals
//void ProcessInDeal(const CDealInfo &d)
//  {
//   CPositionInfo pos;
//   pos.SelectByTicket(deal.PositionId());
//   string symbol = d.Symbol();
//   int size = tradeHist.Size();
//   int index = ArrayResize(tradeHist,size+1)-1;
//
//   tradeHist[index].positionID = d.PositionId();
//   tradeHist[index].sym = d.Symbol();
//   tradeHist[index].entryprice = d.Price();
//   tradeHist[index].sl = pos.StopLoss();
//   tradeHist[index].tp = pos.TakeProfit();
//   tradeHist[index].RAR = allocData.FindByAsset(symbol).riskAdjustReturn;
//   tradeHist[index].DailyReturn = allocData.FindByAsset(symbol).dailyReturns;
//   tradeHist[index].ind1 = IndData(symbol, S_IND_ADX);
//   tradeHist[index].ind2 = IndData(symbol, S_IND_ATR);
//   tradeHist[index].ind3 = IndData(symbol, S_IND_RSI);
//   tradeHist[index].ind4 = IndData(symbol, S_IND_MA);
//   tradeHist[index].profit = NULL; // Initialize profit to zero for "in" deals
//   if(initTrain)
//      predictDF(tradeHist[index].entryprice,tradeHist[index].sl,tradeHist[index].tp,tradeHist[index].RAR,tradeHist[index].DailyReturn,tradeHist[index].ind1,tradeHist[index].ind2,tradeHist[index].ind3,tradeHist[index].ind4);
//  }
//
//// Function to process "out" deals
//void ProcessOutDeal(const CDealInfo &d)
//  {
//// Find the corresponding "in" deal in tradeHist and update its profit
//   for(int i = 0; i < ArraySize(tradeHist); i++)
//     {
//      if(tradeHist[i].positionID == d.PositionId())
//        {
//         // Update the profit for the corresponding "in" deal
//         tradeHist[i].profit = d.Profit();//>0?1:-1;
//
//         // Process or store information as needed for the "out" deal
//         string dealDetails = StringFormat("OUT Deal Details: Ticket=%d, Symbol=%s, Price=%.5f, SL=%.5f, TP=%.5f, RAR=%.5f, Daily Return=%.5f, ADX=%.5f, ATR=%.5f, RSI=%.5f, MA=%.5f, Profit=%.5f",
//                                           d.Ticket(), tradeHist[i].sym, tradeHist[i].entryprice, tradeHist[i].sl, tradeHist[i].tp,
//                                           tradeHist[i].RAR, tradeHist[i].DailyReturn, tradeHist[i].ind1, tradeHist[i].ind2,
//                                           tradeHist[i].ind3, tradeHist[i].ind4, tradeHist[i].profit);
//
//         // Print the concatenated string
//         //Print(dealDetails);
//         break; // Exit the loop once the corresponding "in" deal is found
//        }
//     }
//  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
