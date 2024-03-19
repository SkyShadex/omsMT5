//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+



//CAlglib ml;
CDecisionForestBuilder forestBuilder;
CDecisionForestShell skyforest;
CDFReportShell skyrep;
CMatrixDouble df_DataSet;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void collectDataDF()
  {
   int observations = ArraySize(tradeHist);
   int nonNullRows = 0;

// Count the number of non-NULL rows in tradeHist
   for(int i = 0; i < observations; i++)
     {
      if(tradeHist[i].profit != NULL)
        {
         nonNullRows++;
         //tradeHist[i].profit = tradeHist[i].profit>0?2:1;
        }
     }

// Resize df_DataSet to the correct number of non-NULL rows
   df_DataSet.Resize(nonNullRows, 10);

   int index = 0;

// Iterate through tradeHist
   for(int i = 0; i < observations; i++)
     {
      // Check if profit is not NULL
      if(tradeHist[i].profit != NULL)
        {
         // Set values in each column for the current row
         df_DataSet.Set(index, 0, tradeHist[i].entryprice);
         df_DataSet.Set(index, 1, tradeHist[i].sl);
         df_DataSet.Set(index, 2, tradeHist[i].tp);
         df_DataSet.Set(index, 3, tradeHist[i].RAR);
         df_DataSet.Set(index, 4, tradeHist[i].DailyReturn);
         df_DataSet.Set(index, 5, tradeHist[i].ind1);
         df_DataSet.Set(index, 6, tradeHist[i].ind2);
         df_DataSet.Set(index, 7, tradeHist[i].ind3);
         df_DataSet.Set(index, 8, tradeHist[i].ind4);
         df_DataSet.Set(index, 9, tradeHist[i].profit);
         index++;
        }
     }
     initTrain = true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool initTrain = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void trainDF()
  {
   //static bool initTrain = false;
   //if(!initTrain)
   //  {
   //   initTrain = true;
   //   //collectDataDFInit();
   //   collectDataDF();
   //  }
   collectDataDF();
   //Print(df_DataSet.Row(df_DataSet.Rows()-1));
   df_DataSet.DeleteRow(df_DataSet.Rows()-1); // Your dataset remove last frame
   //Print(df_DataSet.Row(df_DataSet.Rows()-1));

   int df_npoints = df_DataSet.Rows(); // Number of rows in the dataset
   int df_nvars = 8;   // Number of independent variables
   int df_nclasses = 1; // Number of classes for classification problems
   int df_ntrees = 1000; // Number of trees in forest

// Set the dataset to the decision forest builder
   ml.DFBuilderSetDataset(forestBuilder, df_DataSet, df_npoints, df_nvars, df_nclasses);
   ml.DFBuilderSetRndVarsAuto(forestBuilder);
   ml.DFBuilderSetImportanceTrnGini(forestBuilder);
   ml.DFBuilderBuildRandomForest(forestBuilder,df_ntrees,skyforest,skyrep);
   printf("DF Stats: Avg CE = %f // Avg Err = %f // Avg Rel. Err. = %f // OOB Avg CE = %f // OOB Avg Err = %f // OOB Avg Rel. Err. = %f // OOB RMS Err. = %f // OOB Rel. Cls. Err. = %f //",skyrep.GetAvgCE(),skyrep.GetAvgError(),skyrep.GetAvgRelError(),skyrep.GetOOBAvgCE(),skyrep.GetOOBAvgError(),skyrep.GetOOBAvgRelError(),skyrep.GetOOBRMSError(),skyrep.GetOOBRelClsError());
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void predictDF(double xx1,double xx2,double xx3,double xx4,double xx5,double xx6,double xx7,double xx8,double xx9)
  {
   double results[];
   double inputData[9]={xx1,xx2,xx3,xx4,xx5,xx6,xx7,xx8,xx9};
   ml.DFProcess(skyforest,inputData,results); // For regression problems
   //Print(ml.DFClassify(skyforest,inputData)); // For classification problems
   ArrayPrint(results,4);
   printf("DF Stats: Avg CE = %f // Avg Err = %f // Avg Rel. Err. = %f // OOB Avg CE = %f // OOB Avg Err = %f // OOB Avg Rel. Err. = %f // OOB RMS Err. = %f // OOB Rel. Cls. Err. = %f //",skyrep.GetAvgCE(),skyrep.GetAvgError(),skyrep.GetAvgRelError(),skyrep.GetOOBAvgCE(),skyrep.GetOOBAvgError(),skyrep.GetOOBAvgRelError(),skyrep.GetOOBRMSError(),skyrep.GetOOBRelClsError());
  
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
