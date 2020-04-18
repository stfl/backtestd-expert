//+------------------------------------------------------------------+
//|                                                   BykovTrend.mq5 |
//|                                        Ramdass - Conversion only |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Ramdass - Conversion only"
//---- link to the website of the author
#property link      ""
//---- indicator version
#property version   "1.01"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- two buffers are used for calculation and drawing the indicator
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
#property indicator_label1  "BykovTrend Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- lime color is used as the color of a bullish candlestick
#property indicator_color2  Lime
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//---- bearish indicator label display
#property indicator_label2 "BykovTrend Buy"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int RISK=3;
input int SSP=9;
//+----------------------------------------------+
//---- declaration of dynamic arrays that further 
//---- will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---
bool uptrend_,old;
int K,WPR_Handle,ATR_Handle,StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables 
   K=33-RISK;
   StartBars=int(MathMax(SSP,15))+1;
//---- getting handle of the ATR indicator
   WPR_Handle=iWPR(NULL,0,SSP);
   if(WPR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the iWPR indicator");
//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,15);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");

//---- set SellBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//--- create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"BykovTrend Sell");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,234);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);

//---- set BuyBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//--- create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"BykovTrend Buy");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,233);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="BykovTrendSig";
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
   if(BarsCalculated(WPR_Handle)<rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || rates_total<StartBars)
      return(0);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double range,wpr,WPR[],ATR[];
   bool uptrend;

//--- calculations of the necessary amount of data to be copied and
//---- the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      to_copy=rates_total; // calculated number of all bars
      limit=rates_total-StartBars; // starting index for calculation of all bars
      uptrend_=false;
      old=false;
     }
   else
     {
      to_copy=rates_total-prev_calculated+1; // calculated number of new bars only
      limit=rates_total-prev_calculated;     // starting index for calculation of new bars
     }

//---- copy the newly appeared data into the WPR[] and ATR[] arrays
   if(CopyBuffer(WPR_Handle,0,0,to_copy,WPR)<=0) return(0);
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(0);

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(WPR,true);
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- restore values of the variables
   uptrend=uptrend_;

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         uptrend_=uptrend;
        }

      wpr=WPR[bar];
      range=ATR[bar]*3/8;

      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(wpr<-100+K) uptrend=false;
      if(wpr>-K)     uptrend=true;

      if(!old &&  uptrend) BuyBuffer [bar]=low [bar]-range;
      if( old && !uptrend) SellBuffer[bar]=high[bar]+range;

      if(bar) old=uptrend;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
