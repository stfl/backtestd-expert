/*
//+------------------------------------------------------------------+
//|                                                           Go.mq5 |
//|                             Copyright © 2006, Victor Chebotariov |
//|                                      http://www.chebotariov.com/ |
//+------------------------------------------------------------------+
  | Place the SmoothAlgorithms.mqh file                              |
  | to the terminal_data_folder\MQL5\Include                         |
  +------------------------------------------------------------------+
*/
#property copyright "Copyright © 2006, Victor Chebotariov"
#property link      "http://www.chebotariov.com/"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a three-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- two colors are used for the histogram color
#property indicator_color1 Gray,Lime,Red
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the signal line label
#property indicator_label1  "Go"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Period_=174; // Indicator period 
input int Shift=0;     // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtBuffer[],ColorExtBuffer[];
//+------------------------------------------------------------------+
//| Smoothing classes description                                    |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- set ExtBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtBuffer,INDICATOR_DATA);
//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Go(",Period_,")");
//---- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- create label to display in Data Window
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,Period_);
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- set ColorExtBuffer[] dynamic array as an indicator buffer   
   SetIndexBuffer(1,ColorExtBuffer,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,Period_);
//---- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
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
   if(rates_total<Period_+1) return(0);

//---- declarations of local variables 
   int first1,first2,bar;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first1=0; // starting index for calculation of all bars
      first2=Period_+1;
     }
   else
     {
      first1=prev_calculated-1; // starting index for calculation of new bars
      first2=first1;
     }
     
//---- declaration of the Moving_Average and StdDeviation classes
   static CMoving_Average MA;

//---- main indicator calculation loop
   for(bar=first1; bar<rates_total; bar++)
      ExtBuffer[bar]=MA.MASeries(0,prev_calculated,rates_total,Period_,MODE_SMA,close[bar]-open[bar],bar,false)/_Point;

//---- main cycle of the indicator coloring
   for(bar=first2; bar<rates_total; bar++)
     {
      ColorExtBuffer[bar]=0;
      if(ExtBuffer[bar]>0) ColorExtBuffer[bar]=1;
      if(ExtBuffer[bar]<0) ColorExtBuffer[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
