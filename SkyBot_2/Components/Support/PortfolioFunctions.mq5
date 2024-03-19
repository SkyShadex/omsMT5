//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPortfolioAssist
  {
public:

   //+------------------------------------------------------------------+
   //|                        Position Related                          |
   //+------------------------------------------------------------------+
   void              KillSwitch()
     {
      for(int j = 2; j >= 0; j--)
        {
         CloseAllPositions("all");
         CloseAllOrders("all");
        }
     }



   bool              CloseAllPositions(string symbol)
     {
      bool positionsClosed = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(symbol == "all")
           {
            trade.PositionClose(ticket);
            positionsClosed = true;
           }
         if(PositionGetString(POSITION_SYMBOL) == symbol)
           {
            trade.PositionClose(ticket);
            positionsClosed = true;
           }
        }
      if(positionsClosed)
        {
         Print(symbol, ": Closing Positions");
        }
      else
        {
         if(debug)
            Print(symbol, ": No Open Positions Found");
        }
      return positionsClosed;
     }

   int               CountPositions(string symbol)
     {
      int positions = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetString(POSITION_SYMBOL) == symbol)
           {
            positions++;
           }
        }
      return positions;
     }

   void              ModifyAllPositions(string symbol, double stoplossPrice)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetString(POSITION_SYMBOL) == symbol)
           {
            if(trade.PositionModify(ticket, stoplossPrice, PositionGetDouble(POSITION_TP)))
               Print(__FUNCTION__, ": Breakeven Point Detected. Adjusting Stops. ", symbol, " #", ticket);
           }
        }
     }

   void              TrimAllPositions(string symbol, double trimFactor)
     {
      bool positionsClosed = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetString(POSITION_SYMBOL) == symbol)
           {
            if(PositionSelectByTicket(ticket))
              {
               double pos_Lots = PositionGetDouble(POSITION_VOLUME);
               pos_Lots = ps.RoundLots(pos_Lots * trimFactor, symbol);
               if(trade.PositionClosePartial(ticket, pos_Lots, -1))
                  positionsClosed = true;
              }
           }
        }
      if(positionsClosed)
        {
         Print(symbol, ": Trimming Positions. ", trimFactor);
        }
      else
        {
         if(debug)
            Print(symbol, ": No Open Positions Found");
        }
     }

   //+------------------------------------------------------------------+
   //|                        Order Related                             |
   //+------------------------------------------------------------------+
   int               CountOrders(string symbol)
     {
      int orders = 0;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         ulong ticket = OrderGetTicket(i);
         if(OrderGetString(ORDER_SYMBOL) == symbol)
           {
            orders++;
           }
        }
      return orders;
     }


   void              CloseAllOrders(string symbol)
     {
      bool ordersClosed = false;
      int ord_total=OrdersTotal();
      if(ord_total > 0)
        {
         for(int i = ord_total - 1; i >= 0; i--)
           {
            ulong ticket=OrderGetTicket(i);
            if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL)==symbol)
              {
               trade.OrderDelete(ticket);
               ordersClosed = true;
              }
            if(OrderSelect(ticket) && symbol=="all")
              {
               trade.OrderDelete(ticket);
               ordersClosed = true;
              }
           }
        }
      if(ordersClosed)
        {
         Print(symbol,": Closing Orders");
        }
      else
        {
         if(debug)
            Print(symbol,": No Open Orders Found");
        }
     }

   void              positionBreakeven(int Side, double pos_OpenPrice, double pos_TP, ulong ticket, string symbol, int points, double ticksize)
     {
      double new_SL;
      if(Side == POSITION_TYPE_BUY)
        {
         new_SL = pos_OpenPrice+(points*ticksize);
        }
      else
        {
         new_SL = pos_OpenPrice-(points*ticksize);
        }
      if(trade.PositionModify(ticket, new_SL, pos_TP))
        {
         Print(__FUNCTION__, ": Breakeven Point Detected. Adjusting Stops. ", symbol, " #", ticket);
        }
     }
  };



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getOldestPositionInfo(const string symbol, const int side, const string option)
  {
   double oldestPos = 0;
   ulong oldestTicket = 0;
   double oldestPrice = 0, price = 0, positions = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {

      string posSymbol = PositionGetString(POSITION_SYMBOL);
      if(posSymbol != symbol)
         continue;

      ulong ticket = PositionGetTicket(i);
      long posType = PositionGetInteger(POSITION_TYPE);
      long posTime = PositionGetInteger(POSITION_TIME);

      if(option == "age")
        {
         long posAge = TimeCurrent() - posTime;
         if(posAge > oldestPos)
           {
            oldestPos = (double)posAge;
            continue;
           }
        }
      else
         if(option == "newest")
           {
            long posAge = TimeCurrent() - posTime;
            if(posAge < oldestPos || oldestPos == 0)
              {
               oldestPos = (double)posAge;
               continue;
              }
           }
         else
            if(option == "avg")
              {
               price += PositionGetDouble(POSITION_PRICE_OPEN);
               positions++;
              }
            else
               if(option == "last" && side != posType)
                 {
                  double curPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  price = (price == 0) ? curPrice : price;

                  if((posType == POSITION_TYPE_SELL && price > curPrice) || (posType == POSITION_TYPE_BUY && price < curPrice))
                     price = curPrice;
                 }
               else
                  if(option == NULL && side != posType)
                    {
                     long posAge = TimeCurrent() - posTime;
                     if(posAge > oldestPos)
                       {
                        oldestPos = (double)posAge;
                        oldestTicket = ticket;
                       }
                    }
     }

   if(option == "age" || option == "lastage" || option == "newest")
      return oldestPos;
   else
      if(option == "last")
         return price;
      else
         if(option == "avg" && positions > 0)
            return price / positions;

   if(PositionSelectByTicket(oldestTicket))
     {
      oldestPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      if(debug)
         Print(oldestPrice);
      return oldestPrice;
     }

   return 0.0;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateTotalProfit(const string symbol)
  {
   double totalProfit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == symbol)
           {
            double pos_Profit = PositionGetDouble(POSITION_PROFIT);
            totalProfit += pos_Profit;
           }
        }
     }
   return totalProfit;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetOrderHistory(const string symbol,datetime startDate, int &trades, double &totalPnl, double &pnlArray[])
  {
//--- select history for access
   HistorySelect(startDate,TimeCurrent());
//---
   int orders=HistoryDealsTotal();  // total history deals
//---
   for(int i=orders-1; i>=0; i--)
     {
      deal.Ticket(HistoryDealGetTicket(i));
      if(deal.Ticket()==0)
        {
         Print("HistoryDealGetTicket failed, no trade history");
         break;
        }
      //--- check symbol
      if(deal.Symbol()!=symbol)
         continue;

      //--- check profit
      double current_profit = deal.Profit() + deal.Commission() + deal.Swap();
      if(current_profit == 0.0)  // eliminate the second leg of the deal
         continue;

      //--- count trades
      trades++;

      //--- check profit
      totalPnl += current_profit;

      // Store individual PnL value in the array
      ArrayResize(pnlArray, ArraySize(pnlArray) + 1);
      pnlArray[ArraySize(pnlArray) - 1] = current_profit;
      //printf(__FUNCTION__+": %s , trades %d , losses %d , profit %.2f, current p %.2f ",symbol,trades,losses,pnl,current_profit);
     }

//printf(__FUNCTION__+": %s , trades %d , losses %d , profit %.2f ",symbol,trades,losses,pnl);
  }


//+------------------------------------------------------------------+
//|                 For use with Matrix                              |
//+------------------------------------------------------------------+
void GetOrderHistory(const string symbol, datetime startDate, CMatrixDouble &orderHistoryMatrix)
  {
   CHistoryOrderInfo history;
//--- select history for access
   HistorySelect(startDate, TimeCurrent());
//---
   int orders = HistoryDealsTotal(); // total history deals
   int trades = 0;
   double totalPnL = 0;
   double totalPnL_percent = 0;
   orderHistoryMatrix.Resize(1, 5);
//---
   for(int i = orders - 1; i >= 0; i--)
     {
      deal.Ticket(HistoryDealGetTicket(i));
      if(deal.Ticket() == 0)
        {
         Print("HistoryDealGetTicket failed, no trade history");
         break;
        }
      //--- check symbol
      if(deal.Symbol() != symbol && symbol != "ALL")
         continue;

      //--- check profit
      if(deal.Profit() == NULL || deal.Price() == 0)  // eliminate the second leg of the deal
         continue;

      double current_profit = deal.Profit() + deal.Commission() + deal.Swap();
      double current_profit_percent = CalculatePercentagePriceChange(deal.Symbol(),deal.Price(),deal.Volume(),current_profit);
      //--- count trades
      trades++;

      //--- check profit
      totalPnL += current_profit;


      history.SelectByIndex((int)HistoryOrderGetTicket(i));
      // Add individual trade data to the matrix
      orderHistoryMatrix.Resize(trades, 5); // Resize to accommodate new row
      orderHistoryMatrix.Set(trades - 1, 0, trades);                                             // Order index
      orderHistoryMatrix.Set(trades - 1, 1, current_profit);                                      // Individual profit
      orderHistoryMatrix.Set(trades - 1, 2, totalPnL);                                           // Cumulative profit
      orderHistoryMatrix.Set(trades - 1, 3, (deal.Price() - history.StopLoss()) / deal.Price() * 100); // SL Percentage
      orderHistoryMatrix.Set(trades - 1, 4, current_profit_percent); // SL Percentage
      //Print(orderHistoryMatrix.Row(trades-1));
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetPriceHistory(const string symbol, datetime startDate, CMatrixDouble &returnsMatrix)
  {

   matrix matrix_rates;
   double bars = 800;
   if(!matrix_rates.CopyRates(symbol, PERIOD_H6, COPY_RATES_OHLC, 1, bars))
      return;

   double totalReturns = 0.0;
   int copiedBars = (int)matrix_rates.Cols();
   if(copiedBars<2)
      return;
// Resize the matrix outside the loop
   returnsMatrix.Resize(copiedBars, 3);

   for(int i = copiedBars - 1; i > 0; i--)
     {

      // Calculate log returns
      double logReturn = MathLog(matrix_rates[3][i] / matrix_rates[3][i - 1]);
      //double rawReturn = matrix_rates[3][i] - matrix_rates[3][i - 1];
      double Returns = logReturn;
      if(Returns == 0.0)
         continue;
      // Calculate cumulative log returns
      totalReturns+= Returns;

      // Add individual trade data to the matrix
      returnsMatrix.Set(i, 0, i);                // Bar index
      returnsMatrix.Set(i, 1, Returns);        // Log Returns
      returnsMatrix.Set(i, 2, totalReturns);   // Cumulative Log Returns
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculatePercentagePriceChange(string symbol, double exitPrice, double lotSize, double profit)
  {
   if(lotSize == 0.0)
     {
      Print("Error: Lot size cannot be zero.");
      return 0.0;  // Avoid division by zero
     }

   double deltaPerLot= SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE)/SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double percentageChange = (profit / (lotSize * (exitPrice*deltaPerLot)));
   //printf("%s, %.5f, %.5f, %.5f, %.5f",symbol,exitPrice,lotSize,profit,percentageChange);
   return percentageChange;
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
