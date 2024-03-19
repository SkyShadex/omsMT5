//+------------------------------------------------------------------+
//|                                               ATRSpreadRatio.mq5 |
//|                                                        SkyShadex |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


#property copyright "SkyShadex"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4
#property indicator_minimum -1
#property indicator_maximum 5
#property indicator_level1 1
#property indicator_level2 2
#property indicator_level3 3
#property indicator_level4 4


//--- plot Spread
#property indicator_label1  "Spread"
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrGreenYellow
#property indicator_style1  STYLE_DASH
#property indicator_width1  1
//--- plot ATR
#property indicator_label2  "ATR"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DASH
#property indicator_width2  1
//--- plot Ratio
#property indicator_label3  "Ratio"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDeepSkyBlue
#property indicator_style3  STYLE_DASH
#property indicator_width3  1

//--- plot Ratio
#property indicator_label4  "lnRatio"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrPurple
#property indicator_style4  STYLE_SOLID
#property indicator_width4  3

//--- input parameters
input ENUM_TIMEFRAMES   timeframe = PERIOD_CURRENT;
input int      Periods = 14;
input double   factor = 0.75;
//--- indicator buffers
double         SpreadBuffer[];
double         ATRBuffer[];
double         RatioBuffer[];
double         LogRatioBuffer[];

int handle = iATR(_Symbol,timeframe,14);

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(handle == INVALID_HANDLE)
      handle = iATR(_Symbol,timeframe,14);
//--- indicator buffers mapping
   SetIndexBuffer(0,SpreadBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(1,ATRBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,RatioBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,LogRatioBuffer,INDICATOR_DATA);
   EventSetTimer(1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   handle = iATR(_Symbol,timeframe,14);
//---
   double ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   int barscount = BarsCalculated(handle);
   int valuesToCopy = MathMax(barscount,prev_calculated);
   double preATRBuffer[];
   if(handle !=INVALID_HANDLE)
      CopyBuffer(handle,0,0,valuesToCopy,preATRBuffer);
   else
      return -1;

   for(int i = prev_calculated; i < rates_total; i++)
     {
      double atrCustom = preATRBuffer[i]/ticksize;
      int spreadCustom = spread[i];
      //Print(atrCustom," ",spreadCustom);
      SpreadBuffer[i] = spreadCustom;
      ATRBuffer[i] = atrCustom;
      
      double ratioCustom = (atrCustom*factor)/spreadCustom;
      RatioBuffer[i] = ratioCustom;
      LogRatioBuffer[i] = MathLog(ratioCustom);

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if(handle == INVALID_HANDLE)
      handle = iATR(_Symbol,timeframe,14);
  }


//+------------------------------------------------------------------+
