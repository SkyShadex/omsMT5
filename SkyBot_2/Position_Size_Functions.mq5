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
      rogue_risk = 2;
      
      IsLotVarsValid();

      if(debug)
        {
         Print(__FUNCTION__," ",symbol,": ",ticksize," ",tickvalue," ",lotstep);
         Print(__FUNCTION__," ",symPoint," ",symDigits," ",minvolume," ",maxvolume);
        }
     }


   double            CalcSLDist(double Lots,string _symbol)
     {
      refresh(_symbol);
      if(!IsLotVarsValid())
         return 0.0;

      double riskMoney = NormalizeDouble(riskManager(rogue_risk, _symbol), symDigits);
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
      double moneyPerLotStep = slDistance / ticksize * tickvalue * lotstep;

      if(moneyPerLotStep == 0)
        {
         if(debug)
            Print(__FUNCTION__, 2, " > Lotsize cannot be calculated...");
         return 0;
        }

      double lots = riskMoney / moneyPerLotStep;
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
