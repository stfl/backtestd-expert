//+------------------------------------------------------------------+
//|                                                   ColorJFatl.mq5 |
//|                               Copyright © 2010, Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//| Place the SmoothAlgorithms.mqh file                              |
//| to the terminal_data_folder\MQL5\Include                         |
//+------------------------------------------------------------------+
#property copyright "2010,   Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- one buffer is used for calculation and drawing the indicator
#property indicator_buffers 2
//---- only one plot is used
#property indicator_plots   1
//---- drawing the indicator as a line
#property indicator_type1   DRAW_COLOR_LINE
//---- the following colors are used in a three-colored line
#property indicator_color1  Gray,Gold,Magenta
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1  2
//---- displaying the indicator line label
#property indicator_label1  "JFATL"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // PRICE_CLOSE
   PRICE_OPEN_,          // PRICE_OPEN
   PRICE_HIGH_,          // PRICE_HIGH
   PRICE_LOW_,           // PRICE_LOW
   PRICE_MEDIAN_,        // PRICE_MEDIAN
   PRICE_TYPICAL_,       // PRICE_TYPICAL
   PRICE_WEIGHTED_,      // PRICE_WEIGHTED
   PRICE_SIMPLE,         // PRICE_SIMPLE
   PRICE_QUARTER_,       // PRICE_QUARTER_
   PRICE_TRENDFOLLOW0_,  // PRICE_TRENDFOLLOW0_
   PRICE_TRENDFOLLOW1_   // PRICE_TRENDFOLLOW1_
  };
input int JMALength_=5;                // Depth of JMA smoothing                   
input int JMAPhase_=-100;              // JMA smoothing parameter,
input Applied_price_ IPC=PRICE_CLOSE_; // Applied price
input int FATLShift=0;                 // Horizontal shift of FATL in bars
input int PriceShift=0;                // Vertical shift of FATL in points
//---+
//---- declaration and initialization of a variable for storing the number of calculated bars
int FATLPeriod=39;

//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtLineBuffer[];
double ColorExtLineBuffer[];

int start,fstart,FATLSize;
double dPriceShift;
//+-----------------------------------------------------------+ 
//| Initialization of the coefficients of the digital filter  |
//+-----------------------------------------------------------+ 
double FATLTable_[]=
  {
   +0.4360409450, +0.3658689069, +0.2460452079, +0.1104506886,
   -0.0054034585, -0.0760367731, -0.0933058722, -0.0670110374,
   -0.0190795053, +0.0259609206, +0.0502044896, +0.0477818607,
   +0.0249252327, -0.0047706151, -0.0272432537, -0.0338917071,
   -0.0244141482, -0.0055774838, +0.0128149838, +0.0226522218,
   +0.0208778257, +0.0100299086, -0.0036771622, -0.0136744850,
   -0.0160483392, -0.0108597376, -0.0016060704, +0.0069480557,
   +0.0110573605, +0.0095711419, +0.0040444064, -0.0023824623,
   -0.0067093714, -0.0072003400, -0.0047717710, +0.0005541115,
   +0.0007860160, +0.0130129076, +0.0040364019
  };
//+------------------------------------------------------------------+
//| iPriceSeries() function description                              |
//| iPriceSeriesAlert() function description                         |
//| CJJMA class description                                          |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh>  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- set ExtLineBuffer as indicator buffer
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- shifting the indicator horizontally by FATLShift
   PlotIndexSetInteger(0,PLOT_SHIFT,FATLShift);
//---- initialization of variables 
   FATLSize=ArraySize(FATLTable_);
   start=FATLSize+30;
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,start);
//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"JFATL(",JMALength_," ,",JMAPhase_,")");
//--- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//--- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- set dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorExtLineBuffer,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,start+1);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);

//---- initialization of the vertical shift
   dPriceShift=_Point*PriceShift;
//---- declaration of the variable of the CJJMA class from the SmoothAlgorithms.mqh file
   CJJMA JMA;
//---- setting up alerts for unacceptable values of external variables
   JMA.JJMALengthCheck("Length_", JMALength_);
   JMA.JJMAPhaseCheck("Phase_", JMAPhase_);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // amount of history in bars at the current tick
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
   if(rates_total<start)
      return(0);

//---- declarations of local variables 
   int first,bar;
   double jfatl,FATL;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=FATLPeriod-1; // starting index for calculation of all bars
      fstart=first;
     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- declaration of the variable of the CJJMA class from the SmoothAlgorithms.mqh file
   static CJJMA JMA;

//---- main indicator calculation loop
   for(bar=first; bar<rates_total; bar++)
     {
      //---- formula for the FATL filter
      FATL=0.0;
      for(int iii=0; iii<FATLSize; iii++)
         FATL+=FATLTable_[iii]*PriceSeries(IPC,bar-iii,open,low,high,close);

      //---- one call of the JJMASeries function. 
      //---- Phase and Length parameters are not changed at every bar (Din = 0) 
      jfatl=JMA.JJMASeries(fstart,prev_calculated,rates_total,0,JMAPhase_,JMALength_,FATL,bar,false);

      //---- initialization of the cell of the indicator buffer by the obtained value of FATL
      ExtLineBuffer[bar]=jfatl+dPriceShift;
     }

//---- recalculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
      first++;

//---- main loop of the signal line coloring
   for(bar=first; bar<rates_total; bar++)
     {
      ColorExtLineBuffer[bar]=0;
      if(ExtLineBuffer[bar-1]<ExtLineBuffer[bar]) ColorExtLineBuffer[bar]=1;
      if(ExtLineBuffer[bar-1]>ExtLineBuffer[bar]) ColorExtLineBuffer[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
