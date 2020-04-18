//+------------------------------------------------------------------+
//|                                                     ASCtrend.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "ASCtrend"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- one buffer is used for calculation and drawing the indicator
#property indicator_buffers 2
//---- only two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- magenta color is used as the color of the bearish indicator line
#property indicator_color1  Magenta
//---- indicator 1 line width is equal to 4
#property indicator_width1  4
//---- bullish indicator label display
#property indicator_label1  "ASCtrend Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- blue color is used for the indicator bullish line
#property indicator_color2  Blue
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//---- bearish indicator label display
#property indicator_label2 "ASCtrend Buy"

#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int RISK=4;
//+----------------------------------------------+

//---- declaration of dynamic arrays that further 
//---- will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//----
int  StartBars,x1,x2,value10,value11,WPR_Handle[3];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables   
   x1=67+RISK;
   x2=33-RISK;
   value10=2;
   value11=value10;
   StartBars=int(MathMax(3+RISK*2,4)+1);

//---- getting handle of the iWPR 1 indicator
   WPR_Handle[0]=iWPR(NULL,0,3);
   if(WPR_Handle[0]==INVALID_HANDLE)Print(" Failed to get handle of the iWPR 1 indicator");
//---- getting handle of the iWPR 2 indicator
   WPR_Handle[1]=iWPR(NULL,0,4);
   if(WPR_Handle[1]==INVALID_HANDLE)Print(" Failed to get handle of the iWPR 2 indicator");
//---- getting handle of the iWPR 3 indicator
   WPR_Handle[2]=iWPR(NULL,0,3+RISK*2);
   if(WPR_Handle[2]==INVALID_HANDLE)Print(" Failed to get handle of the iWPR 3 indicator");

//---- set SellBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//--- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"ASCtrend Sell");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   
//---- set BuyBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//---- create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"ASCtrend Buy");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,108);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="ASCtrend";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
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
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(WPR_Handle[0])<rates_total
      || BarsCalculated(WPR_Handle[1])<rates_total
      || BarsCalculated(WPR_Handle[2])<rates_total
      || rates_total<StartBars)
      return(RESET);

//---- declarations of local variables 
   int limit,bar,count,iii;
   double value2,value3,Vel=0,WPR[];
   double TrueCount,Range,AvgRange,MRO1,MRO2;

//--- calculations of the necessary amount of data to be copied and
//--- the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
        limit=rates_total-StartBars; // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(WPR,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Range=0.0;
      AvgRange=0.0;
      for(count=bar; count<=bar+9; count++) AvgRange=AvgRange+MathAbs(high[count]-low[count]);

      Range=AvgRange/10;
      count=bar;
      TrueCount=0;

      while(count<bar+9 && TrueCount<1)
        {
         if(MathAbs(open[count]-close[count+1])>=Range*2.0) TrueCount++;
         count++;
        }

      if(TrueCount>=1) MRO1=count;
      else             MRO1=-1;

      count=bar;
      TrueCount=0;

      while(count<bar+6 && TrueCount<1)
        {
         if(MathAbs(close[count+3]-close[count])>=Range*4.6) TrueCount++;
         count++;
        }

      if(TrueCount>=1) MRO2=count;
      else             MRO2=-1;

      if(MRO1>-1) {value11=0;} else {value11=value10;}
      if(MRO2>-1) {value11=1;} else {value11=value10;}
      
      if(CopyBuffer(WPR_Handle[value11],0,bar,1,WPR)<=0) return(RESET);

      value2=100-MathAbs(WPR[0]); // PercentR(value11=9)
      
      SellBuffer[bar]=0;
      BuyBuffer[bar]=0;
      
      value3=0;

      if(value2<x2)
        {
         iii=1;
         while(bar+iii<rates_total)
           {
           if(CopyBuffer(WPR_Handle[value11],0,bar+iii,1,WPR)<=0) return(RESET);
            Vel=100-MathAbs(WPR[0]);
            if(Vel>=x2 && Vel<=x1) iii++;
            else break;
           }

         if(Vel>x1)
           {
            value3=high[bar]+Range*0.5;
            SellBuffer[bar]=value3;
           }
        }
      if(value2>x1)
        {
         iii=1;
         while(bar+iii<rates_total)
           {
            if(CopyBuffer(WPR_Handle[value11],0,bar+iii,1,WPR)<=0) return(RESET);
            Vel=100-MathAbs(WPR[0]);
            if(Vel>=x2 && Vel<=x1) iii++;
            else break;
           }

         if(Vel<x2)
           {
            value3=low[bar]-Range*0.5;
            BuyBuffer[bar]=value3;
           }
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
