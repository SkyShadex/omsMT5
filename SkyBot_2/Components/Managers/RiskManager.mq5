//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+



input group "Risk Management"
double  Risk = w7; // Risk % per trade
int     Pyramid = 1;
double   atrMultiplier = 0.75;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
class objvector : public CArrayObj
  {
public:
   T  *              operator[](const int index) const { return (T*)At(index);}

   // New method to search for an item based on a string match
   // New method to search for an item based on a string match
   int               FindIndexByAsset(const string& asset) const
     {
      for(int i = 0; i < Total(); ++i)
        {
         T* data = operator[](i);
         if(data && data.asset == asset)
            return i;
        }
      return -1; // Return -1 if not found
     }

   // Access data using the found index
   T *               FindByAsset(const string& asset) const
     {
      int index = FindIndexByAsset(asset);
      if(index != -1)
         return operator[](index);
      else
         return NULL;
     }
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAllocationData : public CObject
  {
public:
   string            asset;
   string            category;
   double            tradingrange;
   double            slPercentage;
   double            risk;
   double            riskAdjustReturn;
   double            beta;
   double            marginNorm;
   double            normLot;
   double            dailyReturns;
   double            covariance;
   double            averageReturn;

                     CAllocationData(string _asset, string _category, double _tradingrange, double _slPercentage, double _risk, double _riskAdjustReturn, double _beta, double _marginNorm) :
                     asset(_asset), category(_category), tradingrange(_tradingrange), slPercentage(_slPercentage), risk(_risk),
                     riskAdjustReturn(_riskAdjustReturn), beta(_beta), marginNorm(_marginNorm) {}

   virtual int       Compare(const CObject *node, const int mode = 0) const override;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CAllocationData::Compare(const CObject *node, const int mode) const
  {
   const CAllocationData *that = dynamic_cast<const CAllocationData*>(node);
   if(!that)
      return 0;  // Not an instance of CAllocationData

   int comp = StringCompare(this.asset, that.asset);

   if(mode == SORT_DESCENDING)
      return -comp;
   else
      return comp;
  }

objvector<CAllocationData> allocData;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initArrs()
  {
   allocData.Add(new CAllocationData("XAUUSD","Metals",0.75,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("XAGUSD","Metals",0.75,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("XAUEUR","Metals",0.75,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("XAUAUD","Metals",0.75,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("XPTUSD","Metals",15,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("XPDUSD","Metals",15,_w2,_w3,NULL,NULL,NULL));
//
   allocData.Add(new CAllocationData("EURUSD","Currencies",0.15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("EURNZD","Currencies",0.00015,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("EURJPY","Currencies",0.25,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("EURCZK","Currencies",1,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("USDJPY","Currencies", 0.5,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("USDCAD","Currencies", 0.5,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("USDCHF","Currencies", 0.5,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("AUDJPY","Currencies",0.15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("AUDNZD","Currencies",0.15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("AUDUSD","Currencies",0.15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("AUDCAD","Currencies",0.15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("GBPUSD","Currencies",0.05,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("GBPCHF","Currencies",0.5,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("NZDUSD","Currencies",0.5,_w2,_w3,NULL,NULL,NULL));
//
//allocData.Add(new CAllocationData("XMRUSD","Cryptos",10,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("XRPUSD","Cryptos",10,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("LTCUSD","Cryptos",10,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("BTCUSD","Cryptos",10,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("DASHUSD","Cryptos",10,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("ETHUSD","Cryptos",10,_w2,_w3,NULL,NULL,NULL));
//
//allocData.Add(new CAllocationData("US30.cash","Indices",15,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("US100.cash","Indices",15,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("US500.cash","Indices",15,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("US2000.cash","Indices",15,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("JP225.cash","Indices",15*50,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("HK50.cash","Indices", 15,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("EU50.cash","Indices", 15,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("AUS200.cash","Indices",7,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("GER40.cash","Indices",7,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("FRA40.cash","Indices",8,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("SPN35.cash","Indices",5,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("US30","Indices", 15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("DAX40","Indices", 15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("JPN225","Indices", 15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("NAS100","Indices", 15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("SP500","Indices", 15,_w2,_w3,NULL,NULL,NULL));
   allocData.Add(new CAllocationData("UK100","Indices", 15,_w2,_w3,NULL,NULL,NULL));
//
//allocData.Add(new CAllocationData("NATGAS.f","Futures",1,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("USOIL.cash", "Commodities",1,_w2,_w3,NULL,NULL,NULL));
//allocData.Add(new CAllocationData("NVDA","Stocks", 1,_w2,_w3,NULL,NULL,NULL));
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double riskManager(const double RiskPerTrade,const string symbol)
  {
   double ValueAtRisk = accountBalance();

   if(Hedge_Enable)
      ValueAtRisk = ValueAtRisk;



   double allocatedRisk = PositionAllocation(symbol,RiskPerTrade); //TODO: portfolio optimization would go here. The result of this function goes back to the position size functions.
   ValueAtRisk = ValueAtRisk * (allocatedRisk / 100);


   ValueAtRisk = ValueAtRisk*allocData.FindByAsset(symbol).normLot; //Normalizing the deltaPerLot????

//double marginRequired = marginEqualizer(symbol);
//if(marginRequired <= 0.0)
//  {
//   if(debug)
//      Print(__FUNCTION__, 2, " > Margin cannot be calculated...");
//   return NULL;
//  }

//balance = balance/normalizeFunc(marginRequired,marginEqualizer("JP225.cash"),marginEqualizer("GBPUSD"),0.8,1.5,NULL);


//if(debug)
   printf(__FUNCTION__+": Calculated Account Risk for %s: $ %.2f %.2f %% | Kelly Crit: %.8f \n Asset SR: %.4f | Strat SR: %.3f | Corr: %.3f | Beta: %.2f | normLot: %.2f | Avg. Return: %.5f %%",symbol,ValueAtRisk,allocatedRisk,allocData.FindByAsset(symbol).risk,allocData.FindByAsset(symbol).dailyReturns,allocData.FindByAsset(symbol).riskAdjustReturn,allocData.FindByAsset(symbol).covariance,allocData.FindByAsset(symbol).beta,allocData.FindByAsset(symbol).normLot,allocData.FindByAsset(symbol).averageReturn);
   return ValueAtRisk;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateBetaWeights()
  {
   static int size = allocData.Total()-1;
   for(int i=size; i>=0; i--)
     {
      double stratR[],dailyR[],AvgReturn[];

      CMatrixDouble orderHist, priceHist;
      // Based on Strategy PNL
      //TimeCurrent()-PeriodSeconds(PERIOD_D1)*5
      GetOrderHistory(allocData[i].asset,0,orderHist);//TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*2)
      allocData[i].riskAdjustReturn = CalculateRAR("Sortino",orderHist); // Adjust this calculation based on your requirements

      // Based on Asset Daily Returns
      GetPriceHistory(allocData[i].asset,0,priceHist);
      allocData[i].dailyReturns = CalculateRAR("Sortino",priceHist,0); // Adjust this calculation based on your requirements

      if(orderHist.Rows()>priceHist.Rows())
         continue;

      int vectorSize = orderHist.Rows();
      ArrayResize(stratR, vectorSize);
      ArrayResize(AvgReturn, vectorSize);
      for(int j = 0; j < vectorSize; j++)
        {
         stratR[j] = orderHist.Get(j, 2);
         AvgReturn[j] = orderHist.Get(j, 4);
        }

      ArrayResize(dailyR, vectorSize);
      for(int j = vectorSize-1; j > 0; j--)
        {
         dailyR[j] = priceHist.Get(j, 2);
        }
      ArrayReverse(dailyR,0,WHOLE_ARRAY);

      // Perform Pearson correlation
      allocData[i].covariance = ml.PearsonCorr2(dailyR, stratR);
      allocData[i].averageReturn = MathMean(AvgReturn);
     }
   NormalizeBetas(0,1); // Normalize Betas for the time being
  }


//+------------------------------------------------------------------+
//|                       Matrix                                     |
//+------------------------------------------------------------------+
double CalculateRAR(string mode,const CMatrixDouble &input_matrix, double monthlyRate = 0.1)
  {
   int trades = input_matrix.Rows();
   if(trades==0)
      return 0.0;
//static const double monthlyRate = 0.1;  // Monthly target return
   static const int tradingDaysInMonth = 21;  // Number of trading days in a month (or your preferred value)
   double riskFreeRate = MathPow(1 + monthlyRate, 1.0 / tradingDaysInMonth) - 1;

// Calculate mean and standard deviation of PnL
   double mean = input_matrix.Col(1).Mean();
   double sumSquaredDifferences = 0.0;

   for(int i = 0; i < trades; i++)
     {
      double difference = input_matrix.Get(i,1) - mean;
      if(mode=="Sortino")
        {
         if(difference < 0)
            sumSquaredDifferences += MathPow(difference,2);
         continue;
        }
      else
         sumSquaredDifferences += MathPow(difference,2);
     }

   double standardDeviation = MathSqrt(sumSquaredDifferences / trades);

// Avoid division by zero
   if(standardDeviation != 0.0)
     {
      // Calculate Sharpe Ratio
      double RAR = ((mean - riskFreeRate) / standardDeviation) * MathSqrt(252); // Assuming 25 trading days in a month MathMin(trades,21)

      return RAR;
     }

   return 0.0; // Return 0 if standard deviation is zero
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NormalizeBetas(int min, int max)
  {
// Find the minimum and maximum beta values
   double minBeta = DBL_MAX;
   double maxBeta = -DBL_MAX;
   static int size = allocData.Total()-1;
   for(int i=size; i>=0; i--)
     {
      if(allocData[i].riskAdjustReturn == NULL)
         continue;
      if(allocData[i].riskAdjustReturn < minBeta)
         minBeta = allocData[i].riskAdjustReturn;
      if(allocData[i].riskAdjustReturn > maxBeta)
         maxBeta = allocData[i].riskAdjustReturn;
     }

// Normalize beta values between 0 and 1
   for(int i=size; i>=0; i--)
     {
      string b = allocData[i].asset;
      double RAR = allocData[i].riskAdjustReturn; // the inverse of RaR
      if(RAR==0)
         continue;
      RAR = 1/RAR;
      double normalizedBeta = normalizeFunc(RAR,minBeta,maxBeta,min,max,NULL);
      allocData[i].beta = normalizedBeta;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateKellyCrit(string symbol)
  {
   static const double monthlyRate = 0.1;  // Monthly target return (There is no payout below this value)
   static const int tradingDaysInMonth = 21;  // Number of trading days in a month (or your preferred value)
   static const double riskFreeRate = MathPow(1 + monthlyRate, 1.0 / tradingDaysInMonth) - 1;
   static double portfolioKC = 0.0;

   CMatrixDouble orderHistory;
//TimeCurrent()-PeriodSeconds(PERIOD_D1)*5
   GetOrderHistory(symbol,0,orderHistory);
   double RiskAdjReturn = CalculateRAR("Sortino",orderHistory);
   double kelly = 0.0, averageWin = 0.0, winrate = 0.0;
   int totalTrades = orderHistory.Rows();

// Check if there are trades in the order history
   if(totalTrades > 0)
     {
      for(int i = 0; i < totalTrades; ++i)
        {
         double profit = orderHistory[i][1]; // Assuming profit is in the second column

         // Only consider winning trades

           {
            averageWin += profit;
            if(profit > 0)
               winrate += 1.0; // Increment winrate for each winning trade
           }
        }

      // Calculate averageWin and winrate
      if(winrate > 0)
        {
         averageWin /= winrate; // Calculate averageWin
         winrate /= totalTrades; // Calculate winrate
        }

      if(RiskAdjReturn == 0 || averageWin == 0)
         return Risk;

      // Calculate Kelly Criterion
      kelly = (winrate - (riskFreeRate / RiskAdjReturn)) / averageWin;
      kelly = kelly<DBL_MIN?portfolioKC:kelly>Risk?portfolioKC:kelly;
      // Print or use the calculated Kelly Criterion
      if(symbol=="ALL")
        {
         portfolioKC = MathMax(portfolioKC,kelly);
         printf(__FUNCTION__+" Kelly Criterion for %s: %.8f Current Risk: %.4f", symbol, kelly, Risk);
        }
      return kelly/2;

     }
   else
     {
      Print("No Valid trades in the order history. Unable to calculate Kelly Criterion.");
     }
   return Risk;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateStats(bool print = true)
  {

   double RaR[];
   double Beta[];
   double Kelly[];
   double Daily[];
   double Corr[];
   double AvgReturn[];
   static int size = allocData.Total();
   ArrayResize(RaR,size,0);
   ArrayResize(Beta,size,0);
   ArrayResize(Kelly,size,0);
   ArrayResize(Daily,size,0);
   ArrayResize(Corr,size,0);
   ArrayResize(AvgReturn,size,0);
   for(int i=size-1; i>=0; i--)
     {
      RaR[i] = allocData[i].riskAdjustReturn;
      Beta[i] = allocData[i].beta;
      Kelly[i] = allocData[i].risk;
      Daily[i] = allocData[i].dailyReturns;
      Corr[i] = allocData[i].covariance;
      AvgReturn[i] = allocData[i].averageReturn;
     }

   double mean,variance,skewness,kurtosis;
   cstat.SampleMoments(RaR,RaR.Size(),mean,variance,skewness,kurtosis);
   double res = variance;
   if(print)
     {
      printf(__FUNCTION__+" Risk Adj. Return: Mean: %.3f Variance: %.3f Skewness: %.3f Kurtosis: %.3f",mean,variance,skewness,kurtosis);
      cstat.SampleMoments(Daily,Daily.Size(),mean,variance,skewness,kurtosis);
      printf(__FUNCTION__+" Daily Return: Mean: %.3f Variance: %.3f Skewness: %.3f Kurtosis: %.3f",mean,variance,skewness,kurtosis);
      //cstat.SampleMoments(Beta,Beta.Size(),mean,variance,skewness,kurtosis);
      //printf(__FUNCTION__+" Norm. Risk Adj. Return: Mean: %.3f Variance: %.3f Skewness: %.3f Kurtosis: %.3f",mean,variance,skewness,kurtosis);
      cstat.SampleMoments(Corr,Corr.Size(),mean,variance,skewness,kurtosis);
      printf(__FUNCTION__+" Pearson Corr. : Mean: %.3f Variance: %.3f Skewness: %.3f Kurtosis: %.3f",mean,variance,skewness,kurtosis);
      cstat.SampleMoments(Kelly,Kelly.Size(),mean,variance,skewness,kurtosis);
      printf(__FUNCTION__+" Kelly Crit. : Mean: %.3f Variance: %.3f Skewness: %.3f Kurtosis: %.3f",mean,variance,skewness,kurtosis);
      cstat.SampleMoments(AvgReturn,AvgReturn.Size(),mean,variance,skewness,kurtosis);
      printf(__FUNCTION__+" AvgReturn. : Mean: %.3f Variance: %.3f Skewness: %.3f Kurtosis: %.3f",mean,variance,skewness,kurtosis);
     }

   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReportStats()
  {
   static int size = allocData.Total()-1;
   for(int i=size; i>=0; i--)
     {
      double RaR = allocData[i].riskAdjustReturn;
      if(RaR != NULL)
         printf(__FUNCTION__+" %s = Kelly Crit: %.8f SR: %.2f Daily SR: %.4f Corr: %.2f Beta: %.2f normLot: %.2f Avg. Return: %.5f %%",allocData[i].asset,allocData[i].risk,allocData[i].riskAdjustReturn,allocData[i].dailyReturns,allocData[i].covariance,allocData[i].beta,allocData[i].normLot,allocData[i].averageReturn);
     }
   CalculateStats();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double marginEqualizer(const string symbol)
  {
   double  dMargin = 0.0;
   if(allocData.FindByAsset(symbol).marginNorm!=NULL)
      return allocData.FindByAsset(symbol).marginNorm;

   //double ask = SymbolInfoDouble(allocData.FindByAsset(symbol).asset, SYMBOL_ASK);
   //double volSize = SymbolInfoDouble(allocData.FindByAsset(symbol).asset, SYMBOL_VOLUME_MIN);
   //if(!OrderCalcMargin(ORDER_TYPE_BUY,allocData.FindByAsset(symbol).asset,10,10, dMargin))
   //  {
   //   Print("Get1LotMarginRequired: OrderCalcMargin failed to calculate margin required for a 1 lot ", allocData.FindByAsset(symbol).asset," trade! GetLastError(): ", GetLastError());
   //   return dMargin;
   //  }

   dMargin = MathLog(dMargin);

   double ticksize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double deltaPerLot = tickvalue/ticksize;
   dMargin = deltaPerLot;

   if(debug)
      printf(__FUNCTION__+": %s Margin = %.2f",allocData.FindByAsset(symbol).asset,dMargin);
   allocData.FindByAsset(symbol).marginNorm = dMargin;
   return dMargin;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NormalizeDPL(int min, int max)
  {
// Find the minimum and maximum beta values
   double minBeta = DBL_MAX;
   double maxBeta = -DBL_MAX;
   double cumBeta = 0;
   static int size = allocData.Total()-1;
   for(int i=size; i>=0; i--)
     {
      if(allocData[i].marginNorm == NULL)
         continue;
      if(allocData[i].marginNorm < minBeta)
         minBeta = allocData[i].marginNorm;
      if(allocData[i].marginNorm > maxBeta)
         maxBeta = allocData[i].marginNorm;
      cumBeta += allocData[i].marginNorm;
     }

// Normalize beta values between 0 and 1
   for(int i=size; i>=0; i--)
     {
      string b = allocData[i].asset;
      double DPL = allocData[i].marginNorm; // the inverse of RaR
      //if(DPL==0)
      //   continue;
      DPL = 1+(DPL/cumBeta);
      allocData[i].normLot = DPL;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool timeAdjustments(double &ValueAtRisk, double _sun = 1,double _mon = 1,double _tues = 1,double _wed = 1,double _thurs = 1,double _fri = 1,double _sat = 1)
  {
   MqlDateTime dt;
   TimeToStruct(TimeTradeServer(), dt);
   const ENUM_DAY_OF_WEEK day_of_week = (ENUM_DAY_OF_WEEK)dt.day_of_week;

   switch(day_of_week)
     {
      case SUNDAY:
         ValueAtRisk *= _sun;
         return true;
      case MONDAY:
         ValueAtRisk *= _mon;
         return true;
      case TUESDAY:
         ValueAtRisk *= _tues;
         return true;
      case WEDNESDAY:
         ValueAtRisk *= _wed;
         return true;
      case THURSDAY:
         ValueAtRisk *= _thurs;
         return true;
      case FRIDAY:
         ValueAtRisk *= _fri;
         return true;
      case SATURDAY:
         ValueAtRisk *= _sat;
         return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PositionAllocation(const string symbol,const double risk)
  {
   double totalRisk_SR = 0.0;
   double totalRisk_DR = 0.0;

   static int size = allocData.Total()-1;
   for(int i=size; i>=0; i--)
     {
      totalRisk_SR += allocData[i].beta; // collect betas from the array
      totalRisk_DR += allocData[i].dailyReturns;
     }

   if(totalRisk_SR == 0.0)
     {
      // Avoid division by zero
      return risk;
     }

// Calculate the new risk per trade
   double riskparity_SR = risk*(MathMax(allocData.FindByAsset(symbol).beta,DBL_MIN)/totalRisk_SR); // Risk Parity Formula
   double riskparity_DR = risk*(MathMax(allocData.FindByAsset(symbol).dailyReturns,DBL_MIN)/totalRisk_DR); // Risk Parity Formula
   double kelly = risk*MathMax(allocData.FindByAsset(symbol).risk,DBL_MIN); // Kelly Criterion
   double equal = risk/size;
   double riskWeighted = (riskparity_SR);
   if(kelly!=0)
     {
      double x03 = w9;//1; //risk parity
      double y03 = w10;//0.35; //kelly
      double z03 = w11;//0.25; //equal
      double z04 = w12;//1; //daily
      riskWeighted = ((riskparity_SR*x03)+(kelly*y03)+(equal*z03)+(riskparity_DR*z04))/(x03+y03+z03+z04); // This is the weighted result.
     }
   return riskWeighted;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double accountBalance(string mode = "lowest")
  {
   double balance=0;

   if(mode=="lowest")
      balance = fmin(fmin(AccountInfoDouble(ACCOUNT_BALANCE),AccountInfoDouble(ACCOUNT_EQUITY)),AccountInfoDouble(ACCOUNT_MARGIN_FREE));
   if(mode=="margin")
      balance = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(mode=="balance")
      balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(mode=="equity")
      balance = AccountInfoDouble(ACCOUNT_EQUITY);

//if(backtest)
//   balance = fmin(balance,200000);

   return balance;
  }


//+------------------------------------------------------------------+
// Function to rebalance the portfolio
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RebalancePortfolio(string mode)
  {
   static bool trigger = false;
   if(trigger)
      return;

   trigger = true;
   static int size = allocData.Total()-1;
   for(int i=size; i>=0; i--)
     {
      if(mode=="clone")
        {
         if(pa.CloseAllPositions(allocData[i].asset))        // Close any existing positions for the symbol
           {
            CSkySymbolInfo newOrderInfo(allocData[i].asset);
            pushOrder("buy", NULL, newOrderInfo);
           }       // Open a new position with the target size
        }
      else
        {
         pa.CloseAllPositions(allocData[i].asset);
         CSkySymbolInfo newOrderInfo(allocData[i].asset);
         pushOrder("buy", NULL, newOrderInfo);
        }
     }
   Sleep(10000);
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
