//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPositionSizeCalculator
  {
private:
   string            symbol;
   double            ticksize;
   double            tickvalue;
   double            lotstep;
   double            symPoint;
   long               symDigits;
   double            minvolume;
   double            maxvolume;
   double            rogue_risk;
   double            minvolume_OVERRIDE;
   CSkySymbolInfo       s;

   bool              IsLotVarsValid()
     {
      if(ticksize == 0 || tickvalue == 0 || lotstep == 0)
        {
         Print(__FUNCTION__," Invalid Lot Inputs. Lotsize cannot be calculated...");
         return false;
        }
      return true;
     }

public:
                     CPositionSizeCalculator(void) {};


   void              refresh(string _symbol)
     {
      s.New(_symbol);
      symbol = _symbol;
      ticksize = s.ticksize;
      tickvalue = s.tickvalue;
      lotstep = s.lotStep;
      symPoint = s.symPoint;
      symDigits = s.symDigits;
      minvolume = s.minvolume;
      maxvolume = s.maxvolume;
      rogue_risk = Risk/5;
      minvolume_OVERRIDE = minvolume*2;

      IsLotVarsValid();

      if(debug)
        {
         Print(__FUNCTION__," ",symbol,": ",ticksize," ",tickvalue," ",lotstep);
         Print(__FUNCTION__," ",symPoint," ",symDigits," ",minvolume," ",maxvolume);
        }
     }


   double            CalcSLDist(string _symbol,double Lots)
     {
      refresh(_symbol);
      if(!IsLotVarsValid())
         return 0.0;
      double risk = rogue_risk;
      risk = Risk;
      double riskMoney = NormalizeDouble(riskManager(risk, _symbol), symDigits);
      double lots = Lots;
      Print(__FUNCTION__, " Risk Money: ", riskMoney, ", Lots: ", lots);

      if(lots == 0.0)
        {
         if(debug)
            Print(__FUNCTION__, 2, " > Lotsize cannot be calculated...");
         return 0.0;
        }
      double slDistance = (riskMoney / lots) * symPoint;
      slDistance = NormalizeDouble(slDistance, symDigits);
      Print(__FUNCTION__, " slDistance: ", slDistance);
      return slDistance;
     }


   double            CalcLots(double slDistance,string _symbol)
     {
      refresh(_symbol);
      if(!IsLotVarsValid())
         return 0.0;



      double riskMoney = NormalizeDouble(riskManager(Risk,_symbol), symDigits);

      riskMoney = riskMoney;

      double moneyPerLotStep = slDistance * (tickvalue/ticksize);// * lotstep;

      if(moneyPerLotStep == 0.0)
        {
         if(debug)
            Print(__FUNCTION__, 2, " > Lotsize cannot be calculated...");
         return 0.0;
        }

      double lots = riskMoney / (moneyPerLotStep);
      lots = rampLots(symbol,minvolume,lots,w8);
      lots = RoundLots(lots,symbol);
      Print(__FUNCTION__, " Lots: ", lots);
      return lots;
     }



   double            RoundLots(double lots,string _symbol)
     {
      refresh(_symbol);
      if(maxvolume != 0)
        {
         lots = MathMin(lots, maxvolume);
        }

      if(minvolume != 0)
         lots = MathMax(lots, minvolume);
      double remainder = fmod(lots, lotstep);
      if(remainder > 0.0)
        {
         lots = (lots - remainder);  // Round down to the nearest multiple of lotstep
         // Print(__FUNCTION__,": ",remainder," ",split_lots);
        }
      lots = NormalizeDouble(lots, 2);
      return lots;
     }

  };
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double rampLots(string symbol,double minvolume,double lots,int maxReq)
  {
   CMatrixDouble orderHistory;
   GetOrderHistory(symbol,0,orderHistory);
   int totalTrades = orderHistory.Rows();
   lots = normalizeFunc(totalTrades,0,maxReq,minvolume,lots,NULL);
   return lots;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double mm_calc_margin_mode(const string symbol,const double vol_size, const bool bShort = false)
  {
// Local init

   const int               account_leverage        = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
   const double            _price                  = (bShort) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
   double                  margin_rate             = NULL;
   double                  maintenance_rate        = NULL;

   if(!SymbolInfoMarginRate(symbol, ((bShort) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY), margin_rate, maintenance_rate))
     { return(NULL); }


// Select calculation type

   switch((ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE))
     {
      case SYMBOL_CALC_MODE_FOREX:
         return((vol_size / account_leverage) * margin_rate);
      case SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE:
         return(vol_size * margin_rate);
      case SYMBOL_CALC_MODE_CFD:
         return(vol_size * _price * margin_rate);
      case SYMBOL_CALC_MODE_CFDINDEX:
         return((vol_size * _price) * (SymbolInfoDouble(symbol, SYMBOL_POINT) / SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE)) * margin_rate);
      case SYMBOL_CALC_MODE_CFDLEVERAGE:
         return((vol_size * _price) / (account_leverage * margin_rate));
      case SYMBOL_CALC_MODE_EXCH_STOCKS:
         return(vol_size * _price * margin_rate);

      // Not implemented
      case SYMBOL_CALC_MODE_FUTURES:
      case SYMBOL_CALC_MODE_EXCH_FUTURES:
      case SYMBOL_CALC_MODE_EXCH_FUTURES_FORTS:
      case SYMBOL_CALC_MODE_EXCH_BONDS:
      case SYMBOL_CALC_MODE_EXCH_STOCKS_MOEX:
      case SYMBOL_CALC_MODE_EXCH_BONDS_MOEX:
      case SYMBOL_CALC_MODE_SERV_COLLATERAL:
         break;
     }

// Return error
   return(NULL);
  }
//+------------------------------------------------------------------+
