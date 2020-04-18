//+---------------------------------------------------------------------+
//|                                                          RSIOMA.mq5 | 
//|                                           Copyright © 2006, Kalenzo | 
//|                bartlomiej.gorski@gmail.com, http://www.fxservice.eu | 
//+---------------------------------------------------------------------+ 
//| For the indicator to work, place the file SmoothAlgorithms.mqh      |
//| in the directory: terminal_data_folder\MQL5\Include                 |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2006, Kalenzo"
#property link "http://www.fxservice.eu"
//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 3
#property indicator_buffers 3 
//---- two plots are used
#property indicator_plots   2
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- colors of the five-color histogram are as follows
#property indicator_color1 clrDeepPink,clrPurple,clrGray,clrForestGreen,clrLawnGreen
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- Indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the indicator label
#property indicator_label1  "RSIOMA"
//+----------------------------------------------+
//|  Trigger indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator bearish line
#property indicator_color2  clrDarkViolet
//---- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying of the bearish label of the indicator
#property indicator_label2  "Trigger"

//+-----------------------------------+
//|  CXMA class description           |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+

//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA1,XMA2,XMA3,XMA4;
//---- declaration of variables of the class CMomentum from the file SmoothAlgorithms.mqh
CMomentum Mom;
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_ //Type od constant
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price
   PRICE_DEMARK_         //Demark Price
  };
/*enum Smooth_Method - enumeration is declared in SmoothAlgorithms.mqh
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input Smooth_Method RSIOMA_Method=MODE_EMA_; //RSIOMA smoothing method
input uint RSIOMA=14; //RSIOMA smoothing depth                    
input int RSIOMAPhase=15; //RSIOMA smoothing parameter,
                          // for JJMA that can change withing the range -100 ... +100. It impacts the quality of the intermediate process of smoothing;
// For VIDIA, it is a CMO period, for AMA, it is a slow moving average period

input Smooth_Method MARSIOMA_Method=MODE_EMA_; //MARSIOMA smoothing method
input uint MARSIOMA=21; //RSIOMA smoothing depth                    
input int MARSIOMAPhase=15; //RSIOMA smoothing parameter,
                            // for JJMA that can change withing the range -100 ... +100. It impacts the quality of the intermediate process of smoothing;
// For VIDIA, it is a CMO period, for AMA, it is a slow moving average period

input uint MomPeriod=1; //Momentum period

input Applied_price_ IPC=PRICE_CLOSE_;//price constant

input int HighLevel=+20; //trigger top level
input int MiddleLevel=0; //middle of the range
input int LowLevel=-20;  //trigger bottom level

input int Shift=0; // horizontal shift of the indicator in bars 
//+-----------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double IndBuffer[],ColorIndBuffer[],TriggerBuffer[];

//---- Declaration of integer variables of data starting point
int min_rates_total,min_rates_1,min_rates_2,min_rates_3;
//+------------------------------------------------------------------+   
//| RSIOMA indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_1=XMA1.GetStartBars(RSIOMA_Method,RSIOMA,RSIOMAPhase);
   min_rates_2=int(min_rates_1+MomPeriod);
   min_rates_3=int(min_rates_2+RSIOMA+1);
   min_rates_total=min_rates_3+XMA1.GetStartBars(MARSIOMA_Method,MARSIOMA,RSIOMAPhase);

//---- setting alerts for invalid values of external parameters
   XMA1.XMALengthCheck("RSIOMA",RSIOMA);
   XMA1.XMAPhaseCheck("RSIOMAPhase",RSIOMAPhase,RSIOMA_Method);
//---- setting alerts for invalid values of external parameters
   XMA1.XMALengthCheck("MARSIOMA",MARSIOMA);
   XMA1.XMAPhaseCheck("RSIOMAPhase",RSIOMAPhase,MARSIOMA_Method);

//---- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- setting dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- set TriggerBuffer dynamic array as an indicator buffer
   SetIndexBuffer(2,TriggerBuffer,INDICATOR_DATA);

//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);

//---- shifting the starting point of the indicator 2 drawing by min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"RSIOMA");

//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);

//---- the number of the indicator 3 horizontal levels   
   IndicatorSetInteger(INDICATOR_LEVELS,3);
//---- values of the indicator horizontal levels   
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,HighLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,MiddleLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,LowLevel);
//---- gray and magenta colors are used for horizontal levels lines  
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrPurple);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrPurple);
//---- short dot-dash is used for the horizontal level line  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_DASHDOTDOT);
//---- end of initialization
  }
//+------------------------------------------------------------------+ 
//| RSIOMA iteration function                                        | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- checking the number of bars to be enough for calculation
   if(rates_total<min_rates_total) return(0);

//---- declaration of variables with a floating point  
   double price,x1xma,rel,RSI,positive,negative,sump,sumn,res;
   static double prev_positive,prev_negative;
//---- Declaration of integer variables and getting the bars already calculated
   int first,bar,clr;

//---- calculation of the starting number first for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=0; // starting number for calculation of all bars
     }
   else first=prev_calculated-1; // starting number for calculation of new bars

//---- Main calculation loop of the indicator
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(IPC,bar,open,low,high,close);
      x1xma=XMA1.XMASeries(0,prev_calculated,rates_total,RSIOMA_Method,RSIOMAPhase,RSIOMA,price,bar,false);
      rel=Mom.MomentumSeries(min_rates_1,prev_calculated,rates_total,MomPeriod,x1xma,bar,false);

      sump=RSIOMA*XMA2.XMASeries(min_rates_2,prev_calculated,rates_total,MODE_SMA_,0,RSIOMA,+MathMax(rel,0),bar,false);
      sumn=RSIOMA*XMA3.XMASeries(min_rates_2,prev_calculated,rates_total,MODE_SMA_,0,RSIOMA,-MathMin(rel,0),bar,false);

      if(bar==min_rates_3)
        {
         prev_positive=0.0;
         prev_negative=0.0;
        }

      positive=(prev_positive*(RSIOMA-1)+sump)/RSIOMA;
      negative=(prev_negative*(RSIOMA-1)+sumn)/RSIOMA;
      
      if(negative) res=1.0+positive/negative;
      else res=2.0;

      if(res) RSI=50-100/res;
      else RSI=0.0;
      IndBuffer[bar]=RSI;

      TriggerBuffer[bar]=XMA4.XMASeries(min_rates_3,prev_calculated,rates_total,MARSIOMA_Method,MARSIOMAPhase,MARSIOMA,RSI,bar,false);

      if(bar<rates_total-1)
        {
         prev_positive=positive;
         prev_negative=negative;
        }

      clr=2;
      if(RSI>MiddleLevel) {if(RSI>HighLevel) clr=4; else clr=3;}
      if(RSI<MiddleLevel) {if(RSI<LowLevel)  clr=0; else clr=1;}
      ColorIndBuffer[bar]=clr;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
