//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
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
class CIndicatorData : public CObject
  {
public:
   string            asset;
   int               atrHandle;
   int               rsiHandle;
   int               adxHandle;
   int               maHandle;
   CArrayDouble      atrValues;
   CArrayDouble      rsiValues;
   CArrayDouble      adxValues;
   CArrayDouble      maValues;

                     CIndicatorData(string _asset, int _atrHandle, int _rsiHandle, int _adxHandle, int _maHandle) :
                     asset(_asset), atrHandle(_atrHandle), rsiHandle(_rsiHandle), adxHandle(_adxHandle), maHandle(_maHandle),atrValues(), rsiValues(), adxValues(), maValues()
     {}

   virtual int       Compare(const CObject *node, const int mode = 0) const override;
  };

objvector<CIndicatorData> indicatorData;

////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//void InitializeIndicators()
//  {
//   for(int i = 0; i < ArraySize(symGood); ++i)
//     {
//      // Assuming you have the appropriate handles for each indicator for each symbol
//      int atrHandle = iATR(symGood[i], stratTimeframe, 14);
//      int rsiHandle = iRSI(symGood[i], stratTimeframe, 30, PRICE_CLOSE);
//      int adxHandle = iADX(symGood[i], stratTimeframe, 20);
//      int maHandle = iMA(symGood[i], PERIOD_W1, 4, 0, MODE_SMA, PRICE_MEDIAN);
//
//      // Add the instance to the indicatorData objvector
//      indicatorData.Add(new CIndicatorData(symGood[i], atrHandle, rsiHandle, adxHandle, maHandle));
//     }
//   checkIndicator();
//  }
//
//
////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//void checkIndicator()
//  {
//   if(!validIndicators)
//      if(GetIndicatorValuesObj())
//        {
//         validIndicators = true;
//        }
//   validIndicators = false;
//   Print("Indicators Loaded: ", validIndicators);
//  }
//
//
////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//bool GetIndicatorValuesObj()
//  {
//   int size = indicatorData.Total();
//   double indValArray[];
//   int e;
//   ArraySetAsSeries(indValArray, true);
//   int data_needed = 1;
//   bool noErrors = true;
//
//   for(int i=size; i>=0; i--)
//     {
//      int handles[] = {indicatorData[i].atrHandle, indicatorData[i].rsiHandle, indicatorData[i].adxHandle, indicatorData[i].maHandle};
//
//      for(int j = 0; j < 4; j++)
//        {
//         int handle = handles[j];
//         if(handle != INVALID_HANDLE)
//           {
//            for(int k = 0; k < 5; k++)
//              {
//               if(CopyBuffer(handle, 0, 0, data_needed, indValArray) > 0)
//                 {
//                  if(ArraySize(indValArray) >= data_needed)
//                    {
//                     switch(j)
//                       {
//                        case 0:
//                           indicatorData[i].atrValues.AddArray(indValArray);
//                           break;
//                        case 1:
//                           indicatorData[i].rsiValues.AddArray(indValArray);
//                           break;
//                        case 2:
//                           indicatorData[i].adxValues.AddArray(indValArray);
//                           break;
//                        case 3:
//                           indicatorData[i].maValues.AddArray(indValArray);
//                           break;
//                       }
//                     break;
//                    }
//                 }
//               else
//                 {
//                  e = GetLastError();
//                  ResetLastError();
//                  IndicatorRelease(handle);
//                  handles[j] = INVALID_HANDLE;
//                  noErrors = false;
//                  //break; // This works????? IDK WHAT I DID
//                 }
//              }
//           }
//        }
//     }
//
//   if(!noErrors)
//      Print(e);
//   return noErrors;
//  }
//
////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//bool deintHandlesObj()
//  {
//   return indicatorData.Shutdown();
//  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int         symbol_handles[][4];
double      symbol_ind_vals[][8];
bool        validIndicators = false;
const int   numOfIndicators = 4;




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

enum Indicators
  {
   S_IND_ATR = 0,
   S_IND_RSI = 1,
   S_IND_ADX = 2,
   S_IND_MA = 3,
   S_IND_ATRVol = 4,
   S_IND_ATRVolRes = 7
// Add more indicators as needed
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double IndData(string symbol, Indicators ind)
  {
   GetIndicatorValues();
   double result = -1;
   int arrayID = ArrayContainsPosition(symbol,symGood);
   if(arrayID!=-1)
     {
      result = symbol_ind_vals[arrayID][ind];
      if(result>0)
         return result;
      if(ind<numOfIndicators)
        {
         IndicatorRelease(symbol_handles[arrayID][ind]);
         GetIndicatorHandles();
        }
     }

   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool handleCheck(int handle)
  {
   if(handle==INVALID_HANDLE || handle==NULL)
      return true;
   return false;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetIndicatorHandles()
  {
   int size = ArraySize(symGood);
   if(ArrayRange(symbol_handles,0)!=size)
      ArrayResize(symbol_handles,size);
   size = size-1;
//--- An indication of all handles being valid
   bool valid_handles=true;
//--- Iterate over all symbols in a loop and ...
   for(int i=0; i<size; i++)
      for(int j=0; j<numOfIndicators; j++)
        {
         // And if the handle of the current symbol is invalid
         if(symbol_handles[i][j]==INVALID_HANDLE || symbol_handles[i][j]==NULL)
           {
            //--- Get it
            switch(j)
              {
               case 0:
                  symbol_handles[i][j]=iATR(symGood[i], stratTimeframe,14);
                  break;
               case 1:
                  symbol_handles[i][j]=iRSI(symGood[i],stratTimeframe,30,PRICE_CLOSE);
                  break;
               case 2:
                  symbol_handles[i][j]=iADX(symGood[i],stratTimeframe,20);
                  break;
               case 3:
                  symbol_handles[i][j]=iMA(symGood[i],PERIOD_W1,4,0,MODE_SMA,PRICE_MEDIAN);
                  break;
              }
            //--- If the handle could not be obtained, try again next time
            continue;
           }
         if(symbol_handles[i][j]<=0)
            symbol_handles[i][j]=INVALID_HANDLE;
        }
   for(int i=0; i<size; i++)
      for(int j=0; j<numOfIndicators; j++)
         if(symbol_handles[i][j]==INVALID_HANDLE)
           {
            IndicatorRelease(symbol_handles[i][j]);
            valid_handles=false;
            break;
           }

//--- Print the relevant message if the handle for one of the symbols could not be obtained
   if(!valid_handles)
     {
      Print("WHOOPS");
      Sleep(1000);
     }
//---
   return(valid_handles);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetIndicatorValues()
  {
   int size = ArraySize(symGood);
   if(ArrayRange(symbol_ind_vals,0)!=size)
      ArrayResize(symbol_ind_vals,size);
   size = size -1;
   double indValArray[];
   int e;
   ArraySetAsSeries(indValArray, true);
   int data_needed = 1;
   bool noErrors = true;
   for(int i=0; i<size; i++)
      for(int j=0; j<numOfIndicators; j++)
        {
         if(symbol_handles[i][j]!=INVALID_HANDLE)
           {
            for(int k=0; k<5; k++)
              {
               if(CopyBuffer(symbol_handles[i][j], 0, 0, data_needed, indValArray) > 0)
                 {
                  if(ArraySize(indValArray)>=data_needed)
                    {
                     symbol_ind_vals[i][j] = indValArray[0];
                     break;
                    }
                 }
               else
                 {
                  e = GetLastError();
                  ResetLastError();
                  IndicatorRelease(symbol_handles[i][j]);
                  symbol_handles[i][j] = INVALID_HANDLE;
                  GetIndicatorHandles();
                  noErrors = false;
                  //break; // This works????? IDK WHAT I DID
                 }
              }
           }
         else
           {
            noErrors = false;
            //GetIndicatorHandles();
           }
        }
   if(!noErrors)
      Print(e);
   return noErrors;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkIndicators()
  {
   if(!validIndicators)
     {
      bool check = GetIndicatorValues();
      if(check)
        {
         validIndicators = true;
         Print("Indicators Loaded: ",validIndicators);
        }
     }
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool deintHandles()
  {
   int size = ArraySize(symGood);
   if(ArrayRange(symbol_handles,0)!=size)
      ArrayResize(symbol_handles,size);
   size = size-1;
   bool success = true;
   int e;
   for(int i=0; i<size; i++)
      for(int k=0; k<5; k++)
         for(int j=0; j<3; j++)
           {
            if(!IndicatorRelease(symbol_handles[i][j]))
              {
               e = GetLastError();
               success = false;
              }
           }
   ArrayFree(symbol_handles);
   if(!success)
      Print(e);
   return success;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double sentimentScalar(const string symbol, const double posAge, const int countPositions, const double marginLVL, double Input, const double weight1,const double weight2,const string mode,const string mode2)
  {
   double x,y,z,a,b;
   double output = Input;
   const double Scalar_Margin = normalizeFunc(MathLog(marginLVL),MathLog(2000),MathLog(6000),0.1,1,NULL);
   const double Scalar_Age = normalizeFunc(MathLog(posAge),MathLog(1),MathLog(3600*2),1,2,NULL);
   const double Scalar_Positions = normalizeFunc(countPositions,2,10,1,2,NULL);


   x = output*ScalarMacro(symbol,1,weight1,weight2,mode,mode2);
   y = output*Scalar_Margin;
   z = output/Scalar_Age;
   a = output/Scalar_Positions;

   b = (pow(a,1)+pow(z,1)+pow(y,1))/3;
   output = (pow(x,1)+b)/2;



   if(output<0)
      Print(__FUNCTION__,"ERROR <0");


   return MathAbs(output);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ScalarMacro(const string symbol,const double Input,const double weight1,const double weight2,const string mode,const string mode2)
  {
   GetIndicatorValues();

   double x,y,maxScalar,minScalar;
   double output = Input;
   double atrVal = IndData(symbol,S_IND_ATRVolRes);

   if(mode == "increase")
      output = normalizeFunc(atrVal,0,1,output*0.6,output,NULL);
   else
      output = normalizeFunc(atrVal,0,1,output*0.2,output,"inv");

   maxScalar = output*1.1;
   minScalar = output*weight2;

//double volATR = (1+volatilityATR(symbol));
//double optimizer = weight1*volATR;

   double scalarRSI = Scalar_RSI(symbol,minScalar,maxScalar,mode2); //0.1,2
   double scalarADX = Scalar_ADX(symbol,minScalar,maxScalar,mode2);

   if(scalarRSI>-50 && scalarADX>-50)
     {
      x = scalarRSI;
      y = scalarADX;
      output = (x+y)/2;
      output = pow(output,weight1);
     }
   else
      return -1;

   if(output<0)
      Print(__FUNCTION__,"ERROR <0");

   if(mode != "increase")
      output = MathMin(Input,maxScalar);

   return MathAbs(output);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Scalar_RSI(const string symbol,const double minOutput,const double maxOutput,const string mode)
  {
   double rsiCurrent = IndData(symbol,1);
//if(rsiCurrent<=0)
//  {
//   errorRate++;
//   int rsiValue = iRSI(symbol,stratTimeframe,18,PRICE_CLOSE);
//   if(rsiValue != INVALID_HANDLE)
//     {
//      double bufferArray[];
//      ArraySetAsSeries(bufferArray, true);
//      if(CopyBuffer(rsiValue, 0, 0, 10, bufferArray) == 10 && bufferArray[0] != EMPTY_VALUE)
//        {
//         rsiCurrent = bufferArray[0];
//        }
//     }
//  }

   if(rsiCurrent>0)
     {
      double rsiScalar = MathAbs(normalizeFunc(MathLog(rsiCurrent),MathLog(15),MathLog(85),-10,10,NULL));
      if(mode == "inv")
         rsiScalar = normalizeFunc(rsiScalar,0,10,minOutput,maxOutput,"inv");
      else
         rsiScalar = normalizeFunc(rsiScalar,0,10,minOutput,maxOutput,NULL);
      return rsiScalar;
     }
   Print(__FUNCTION__," Indicator Error");
   return -100;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Scalar_ADX(const string symbol,const double minOutput,const double maxOutput,const string mode)
  {

   double adxCurrent = IndData(symbol,2);
//if(adxCurrent<=0)
//  {
//   errorRate++;
//   int adxValue = iADX(symbol,stratTimeframe,5);
//   if(adxValue != INVALID_HANDLE)
//     {
//      double bufferArray[];
//      ArraySetAsSeries(bufferArray, true);
//      if(CopyBuffer(adxValue, 0, 0, 10, bufferArray) == 10 && bufferArray[0] != EMPTY_VALUE)
//        {
//         adxCurrent = bufferArray[0];
//        }
//     }
//  }

   if(adxCurrent>0)
     {
      double adxScalar = MathAbs(normalizeFunc(MathLog(adxCurrent),MathLog(1),MathLog(60),0,10,NULL));
      if(mode == "inv")
         adxScalar = normalizeFunc(adxScalar,0,10,minOutput,maxOutput,"inv");
      else
         adxScalar = normalizeFunc(adxScalar,0,10,minOutput,maxOutput,NULL);
      return adxScalar;
     }
   Print(__FUNCTION__," Indicator Error");
   return -100;
  }



//+------------------------------------------------------------------+
