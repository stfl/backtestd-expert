//+------------------------------------------------------------------+
//|                                                        Sidus.mq5 | 
//|                                  Copyright © 2006, GwadaTradeBoy |
//|                                            racooni_1975@yahoo.fr |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, GwadaTradeBoy"
#property link      "racooni_1975@yahoo.fr"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers 6
#property indicator_buffers 6 
//---- 4 plots are used
#property indicator_plots   4
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- Teal color is used for the indicator
#property indicator_color1  Teal
//---- indicator 1 line width is equal to 4
#property indicator_width1  4
//---- displaying the indicator label
#property indicator_label1 "Sidus Buy"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- MediumVioletRed is used for the indicator
#property indicator_color2  MediumVioletRed
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//---- displaying the indicator label
#property indicator_label2  "Sidus Sell"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a cloud
#property indicator_type3 DRAW_FILLING
//---- BlueViolet and Magenta colors are used for the indicator
#property indicator_color3 BlueViolet,Magenta
//---- displaying the indicator label
#property indicator_label3  "Sidus Fast EMA"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a cloud
#property indicator_type4 DRAW_FILLING
//---- Lime and Red colors are used for the indicator
#property indicator_color4 Lime,Red
//---- displaying the indicator label
#property indicator_label4  "Sidus Fast LWMA"

//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input uint FastEMA=18;                    // Fast EMA period
input uint SlowEMA=28;                    // Slow EMA period
input uint FastLWMA=5;                    // Fast LWMA period
input uint SlowLWMA=8;                    // Slow LWMA period
input ENUM_APPLIED_PRICE IPC=PRICE_CLOSE; // Applied price
extern uint digit=0;                      // Range in points
//+-----------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double FstEmaBuffer[],SlwEmaBuffer[],FstLwmaBuffer[],SlwLwmaBuffer[];
double SellBuffer[],BuyBuffer[];
double DIGIT;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of integer variables for the indicators handles
int FstEma_Handle,SlwEma_Handle,FstLwma_Handle,SlwLwma_Handle,ATR_Handle;
//+------------------------------------------------------------------+   
//| Sidus indicator initialization function                          | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=int(MathMax(FastLWMA,SlowLWMA)+3);

//---- initialization of variables  
   DIGIT=digit*_Point;

//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,15);
   if(ATR_Handle==INVALID_HANDLE) Print(" Failed to get handle of the ATR indicator");

//---- getting handle of the FastEMA indicator
   FstEma_Handle=iMA(NULL,0,FastEMA,0,MODE_EMA,IPC);
   if(FstEma_Handle==INVALID_HANDLE) Print(" Failed to get handle of the FastEMA indicator");

//---- getting handle of the SlowEma indicator
   SlwEma_Handle=iMA(NULL,0,SlowEMA,0,MODE_EMA,IPC);
   if(SlwEma_Handle==INVALID_HANDLE) Print(" Failed to get handle of the SlowEma indicator");

//---- getting handle of the FastLWMA indicator
   FstLwma_Handle=iMA(NULL,0,FastLWMA,0,MODE_LWMA,IPC);
   if(FstLwma_Handle==INVALID_HANDLE) Print(" Failed to get handle of the FastLWMA indicator");

//---- getting handle of the SlowLWMA indicator
   SlwLwma_Handle=iMA(NULL,0,SlowLWMA,0,MODE_LWMA,IPC);
   if(SlwLwma_Handle==INVALID_HANDLE) Print(" Failed to get handle of the SlowLWMA indicator");

//---- set BuyBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,233);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);

//---- set SellBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,234);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);

//---- set FstEmaBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(2,FstEmaBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(FstEmaBuffer,true);

//---- set SlwEmaBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(3,SlwEmaBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(SlwEmaBuffer,true);

//---- set FstLwmaBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(4,FstLwmaBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(FstLwmaBuffer,true);

//---- set SlwLwmaBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(5,SlwLwmaBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as time series
   ArraySetAsSeries(SlwLwmaBuffer,true);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Sidus(",FastEMA,", ",SlowEMA,", ",FastLWMA,", ",SlowLWMA,")");
//--- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- initialization end
  }
//+------------------------------------------------------------------+ 
//| Sidus iteration function                                         | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
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
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(FstEma_Handle)<rates_total
      || BarsCalculated(SlwEma_Handle)<rates_total
      || BarsCalculated(FstLwma_Handle)<rates_total
      || BarsCalculated(SlwLwma_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double range,ATR[];

//---- calculations of the necessary amount of data to be copied
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
      to_copy=rates_total;
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars     
      to_copy=limit+1;
     }

//---- copy the newly appeared data into the ATR[] arrays and indicator buffers
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
   if(CopyBuffer(FstEma_Handle,0,0,to_copy,FstEmaBuffer)<=0) return(RESET);
   if(CopyBuffer(SlwEma_Handle,0,0,to_copy,SlwEmaBuffer)<=0) return(RESET);
   if(CopyBuffer(FstLwma_Handle,0,0,to_copy,FstLwmaBuffer)<=0) return(RESET);
   if(CopyBuffer(SlwLwma_Handle,0,0,to_copy,SlwLwmaBuffer)<=0) return(RESET);

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      range=ATR[bar]*3/8;
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(FstLwmaBuffer[bar]>SlwLwmaBuffer[bar]+DIGIT && FstLwmaBuffer[bar+1]<=SlwLwmaBuffer[bar+1]) BuyBuffer[bar]=low[bar]-range;
      if(SlwLwmaBuffer[bar]>SlwEmaBuffer[bar]+DIGIT && SlwLwmaBuffer[bar+1]<=SlwEmaBuffer[bar]) BuyBuffer[bar]=low[bar]-range;

      if(FstLwmaBuffer[bar]<SlwLwmaBuffer[bar]-DIGIT && FstLwmaBuffer[bar+1]>=SlwLwmaBuffer[bar+1]) SellBuffer[bar]=high[bar]+range;
      if(SlwLwmaBuffer[bar]<SlwEmaBuffer[bar]-DIGIT && SlwLwmaBuffer[bar+1]>=SlwEmaBuffer[bar]) SellBuffer[bar]=high[bar]+range;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
