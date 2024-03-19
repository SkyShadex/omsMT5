//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

input group "Optimization Weights"

input double _w1 = 28;
input double _w2 = 1;
input double ww2 = 0.75;
input double _w3 = 0.63;
input double ww3 = 0.4172;
input double w4 = 0.4; // Position Level Percent BE
input double w5 = 1.002; // Position Level Cash BE
input double w6 = 0.0046; // Portfolio Level TP
input double w7 = 0.57; // Portfolio Level Risk
input double w8 = 44; // Dynamic Ramp Up
input double w9 = 0.79;
input double w10 = 0.998;
input double w11 = 0.72;
input double w12 = 0.26;
input double w13 = 0.86;
input double w14 = 0.84;
input double wDirectionBias = 17;
input double wScrambler = 1;
input double wExit = 2;
input double wControl = 1;
double ff = 100;    //Feed Forward



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimize()
  {
   ff = 15;

   double min = 0.01,max = 0.032;//,step;
   paramQuick("w4",false,0.5+0.25,0.25,true,false,15);
   paramQuick("w5",false,1.002+0.2,0.2,true,false,15);
   paramQuick("w6",false,0.0046+0.005,0.005,true,false,15);
   paramQuick("w7",false,2,1.95,true,false,15);
   paramQuick("w8",false,44,20,true,true,15);
   paramQuick("w9",true,0.52,0.5,true,false,50);
   paramQuick("w10",true,0.52,0.5,true,false,50);
   paramQuick("w11",true,0.52,0.5,true,false,50);
   paramQuick("w12",true,0.52,0.5,true,false,50);

//max = 50;
//   paramQuick("w7",false,156,200,true,true,ff);
//   paramQuick("w8",false,91,200,true,true,ff);


   ParameterSetRange("wScrambler",true,INT_VALUE,1,1,2);
//   ParameterSetRange("wControl",false,INT_VALUE,1,1,20);
   min = 0;
   max = 1000;
 //  ParameterSetRange("wDirectionBias",false,0.1,min,(max-min)*1/ff,max);
 //  ParameterSetRange("wExit",false,INT_VALUE,1,1,2);
//ParameterSetRange("w24",false,INT_VALUE,170000,(int)MathCeil((200000-170000)*1/ff),200000);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void paramQuick(string var, bool on_off, double center, double offset, bool positive,bool isInt,int steps)
  {
   double min = positive?MathMax(center-offset,0.0001):center-offset;
   double max = center+offset;
   double step = (max-min)*1/steps;
   if(isInt)
      ParameterSetRange(var,on_off,0.1,min,MathCeil((int)step),max);
   else
      ParameterSetRange(var,on_off,0.1,min,step,max);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
