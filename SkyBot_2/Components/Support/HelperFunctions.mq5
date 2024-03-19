//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double normalizeFunc(double Input, double minInput,double maxInput,double minOutput,double maxOutput,string mode)
  {
// Calculate the dynamic factor based on margin level (inverse relationship)
   double Output;
   Input = MathMin(Input,maxInput);
   Input = MathMax(Input,minInput);
   
   if(maxInput==minInput)
      return NULL;

   if(mode == "inv")
     {
      Output = maxOutput - (maxOutput - minOutput) * (Input - minInput) / (maxInput - minInput);
     }
   else
     {
      Output = minOutput + (maxOutput - minOutput) * (Input - minInput) / (maxInput - minInput);
     }

// Ensure Output stays within bounds
   Output = MathMin(Output,maxOutput);
   Output = MathMax(Output,minOutput);
   return Output;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ArrayContains(string value, string &arr[])
  {
   for(int i = 0; i < ArraySize(arr); i++)
     {
      if(arr[i] == value)
        {
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ArrayContainsPosition(string value, string &arr[])
  {
   for(int i = 0; i < ArraySize(arr); i++)
      if(arr[i] == value)
        {
         return i;
        }
   return -1;
  }

string analytics;
string lastInput;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void dataUI_Append(string com)
  {
   if(com != lastInput)  // Check if the new input is not identical to the last one
     {
      string old_com = analytics;
      string new_com = com;
      string append_com = old_com + new_com;
      analytics = append_com;
      lastInput = com; // Update the last input to the current one
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void dataUI()
  {
   string com = analytics;
   analytics = NULL;
   Comment(com);
  }
//+------------------------------------------------------------------+
