//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSkySymbolInfo : private CSymbolInfo
  {
private:
   string            _symbol;

public:
   string            symbol;
   double            ticksize, tickvalue, ask, bid, symPoint, deltaPerLot;
   long              spread, symDigits, stopsLevel;
   double            lotStep, minvolume, maxvolume;


                     CSkySymbolInfo(void) {}


                     CSkySymbolInfo(string symbolName)
     {
      _symbol = symbolName;
      Refresh();
     }

   void              New(string symbolName)
     {
      _symbol = symbolName;
      Refresh();
     }
   void              Refresh()
     {
      symbol = _symbol;
      CSymbolInfo s();
      s.Name(symbol);
      ticksize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      tickvalue = MathMax(s.TickValue(),SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE));
      deltaPerLot = tickvalue/ticksize;
      lotStep = MathMax(s.LotsStep(),SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
      ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      spread = MathMax(s.Spread(),SymbolInfoInteger(symbol, SYMBOL_SPREAD));
      symPoint = MathMax(s.Point(),SymbolInfoDouble(symbol, SYMBOL_POINT));
      symDigits = MathMax(s.Digits(),SymbolInfoInteger(symbol, SYMBOL_DIGITS));
      stopsLevel = MathMax(s.StopsLevel(),SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL));
      minvolume = MathMax(s.LotsMin(),SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN));
      maxvolume = MathMax(s.LotsMax(),SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
     }
  };

//+------------------------------------------------------------------+
