//+------------------------------------------------------------------+
//|                                                   Supertrend.mq5 |
//|                   Copyright © 2005, Jason Robinson (jnrtrading). | 
//|                                      http://www.jnrtrading.co.uk | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2005, Jason Robinson (jnrtrading)." 
#property link      "http://www.jnrtrading.co.uk" 
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- number of indicator buffers 4
#property indicator_buffers 4 
//---- four plots are used in total
#property indicator_plots   4
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1 DRAW_LINE
//---- lime color is used for the indicator
#property indicator_color1 Lime
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the signal line label
#property indicator_label1  "Supertrend Up"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type2 DRAW_LINE
//---- three colors are used for the indicator
#property indicator_color2 Red
//---- indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width2 2
//---- displaying the signal line label
#property indicator_label2  "Supertrend Down"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 3 as a label
#property indicator_type3   DRAW_ARROW
//---- medium turquoise color is used as the color of the bullish line of the indicator
#property indicator_color3  MediumTurquoise
//---- the indicator 3 line is a continuous curve
#property indicator_style3  STYLE_SOLID
//---- the indicator 3 line width is equal to 4
#property indicator_width3  4
//---- bullish indicator label display
#property indicator_label3  "Buy Supertrend signal"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a label
#property indicator_type4   DRAW_ARROW
//---- DarkOrange color is used for the indicator bearish line
#property indicator_color4  DarkOrange
//---- the indicator 2 line is a continuous curve
#property indicator_style4  STYLE_SOLID
//---- the indicator 4 line width is equal to 4
#property indicator_width4  4
//---- bearish indicator label display
#property indicator_label4  "Sell Supertrend signal"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int CCIPeriod=50; // CCI indicator period 
input int ATRPeriod=5;  // ATR indicator period
input int Level=0;      // CCI activation level
input int Shift=0;      // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that further 
//---- will be used as indicator buffers
double TrendUp[],TrendDown[];
double SignUp[];
double SignDown[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of integer variables for the indicators handles
int ATR_Handle,CCI_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=MathMax(CCIPeriod,ATRPeriod);
//---- getting handle of the CCI indicator
   CCI_Handle=iCCI(NULL,0,CCIPeriod,PRICE_TYPICAL);
   if(CCI_Handle==INVALID_HANDLE)Print(" Failed to get handle of the CCI indicator");
//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATRPeriod);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");
//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Supertrend(",string(CCIPeriod),", ",string(ATRPeriod),", ",string(Shift),")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);

//---- set ExtBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,TrendUp,INDICATOR_DATA);
//---- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- indexing the elements in buffers as time series   
   ArraySetAsSeries(TrendUp,true);

//---- set ExtBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,TrendDown,INDICATOR_DATA);
//---- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- indexing the elements in buffers as time series   
   ArraySetAsSeries(TrendDown,true);

//---- set SignUp [] dynamic array as an indicator buffer
   SetIndexBuffer(2,SignUp,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as time series   
   ArraySetAsSeries(SignUp,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,108);

//---- set SignDown[] dynamic array as an indicator buffer
   SetIndexBuffer(3,SignDown,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- shifting the start of drawing the indicator 2
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as time series   
   ArraySetAsSeries(SignDown,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,108);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if
   (
    BarsCalculated(CCI_Handle)<rates_total
    || BarsCalculated(ATR_Handle)<rates_total
    || rates_total<min_rates_total
    )
      return(0);

//---- declarations of local variables 
   double ATR[],CCI[];
   int limit,to_copy,bar;

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(CCI,true);

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total;                 // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated;                 // starting index for calculation of new bars
     }

   to_copy=limit+1;

//---- copy newly appeared data in the ATR[] array
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(0);

   to_copy++;
//---- copy newly appeared data in the CCI[] array
   if(CopyBuffer(CCI_Handle,0,0,to_copy,CCI)<=0) return(0);

//---- main indicator calculation loop
   for(bar=limit; bar>=0; bar--)
     {
      TrendUp[bar]=0.0;
      TrendDown[bar]=0.0;
      SignUp[bar]=0.0;
      SignDown[bar]=0.0;

      if(CCI[bar]>=Level && CCI[bar+1]<Level) TrendUp[bar]=TrendDown[bar+1];

      if(CCI[bar]<=Level && CCI[bar+1]>Level) TrendDown[bar]=TrendUp[bar+1];

      if(CCI[bar]>Level)
        {
         TrendUp[bar]=low[bar]-ATR[bar];
         if(TrendUp[bar]<TrendUp[bar+1] && CCI[bar+1]>=Level) TrendUp[bar]=TrendUp[bar+1];
        }

      if(CCI[bar]<Level)
        {
         TrendDown[bar]=high[bar]+ATR[bar];
         if(TrendDown[bar]>TrendDown[bar+1] && CCI[bar+1]<=Level) TrendDown[bar]=TrendDown[bar+1];
        }

      if(TrendDown[bar+1]!=0.0 && TrendUp[bar]!=0.0) SignUp[bar]=TrendUp[bar];

      if(TrendUp[bar+1]!=0.0 && TrendDown[bar]!=0.0) SignDown[bar]=TrendDown[bar];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
