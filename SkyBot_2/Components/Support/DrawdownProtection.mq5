//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#define           GV_DRAWDOWN "GVDRAWDOWN"
#define           GV_OVERRIDE "OVERRIDE"
#define           GV_PERMITTEDLOSS "RISK"


sinput group "Drawdown Protection"
sinput double            StartingBalance = 5000;
sinput double            maxDDP_Limit = 8;
sinput double            dailyDDP_Limit = 4.5;
bool              isDrawdown;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawdownSafety(bool control)
  {
   if(!control)
      return;

   double balance = MathMax(AccountInfoDouble(ACCOUNT_BALANCE),1);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > equityMax)
      equityMax = equity;
   double dailyDDP = NormalizeDouble(((equityMax-equity) / equityMax) * 100,2);
   double maxDDP = NormalizeDouble(((balance-equity) / balance) * 100,2);
   double dailyLimit = dailyDDP_Limit;

   if(debug && false)
      Print(equityMax,"/",dailyDDP,"/",maxDDP,"/",dailyLimit);
   if(GlobalVariableCheck(GV_OVERRIDE)&&GlobalVariableGet(GV_OVERRIDE)>-20)
     {
      double mddoverride =GlobalVariableGet(GV_OVERRIDE);
      mddoverride--;
      Print(__FUNCTION__,": Manual Override. Resetting drawdown...");
      equityMax = 0;
      equity = 0;
      isDrawdown = false;
      GlobalVariableDel(GV_DRAWDOWN);
      if(mddoverride>0)
         GlobalVariableSet(GV_OVERRIDE,mddoverride);
      if(mddoverride<=0)
         GlobalVariableDel(GV_OVERRIDE);
     }
   else
     {
      if(GlobalVariableCheck(GV_DRAWDOWN))
        {
         isDrawdown = true;
         double gv_drawdown = GlobalVariableGet(GV_DRAWDOWN);
         if(gv_drawdown > equityMax)
            equityMax = gv_drawdown;
        }
      if(isNewDay() && GlobalVariableCheck(GV_DRAWDOWN))
        {
         Print(__FUNCTION__,": New day. Resetting drawdown...");
         equityMax = equity;
         isDrawdown = false;
         GlobalVariableDel(GV_DRAWDOWN);
        }
      if(isDrawdown || dailyDDP >= dailyLimit)
        {
         pa.KillSwitch();
         isDrawdown = true;
         //downbad = GlobalVariableGet(GV_PERMITTEDLOSS);
         GlobalVariableSet(GV_DRAWDOWN,equityMax);
        }
     }
   string com = StringFormat("\nMax Drawdown: %.2f%%. Limit: %.2f%%. Status: %s", dailyDDP, dailyLimit, (string)isDrawdown);
   dataUI_Append(com);
  }


//+------------------------------------------------------------------+
