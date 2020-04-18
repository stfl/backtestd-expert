//+------------------------------------------------------------------+
//|                                                         AMkA.mq5 |
//|              MQL4 Code:  Copyright � 2004, GOODMAN & Mstera � AF |
//|              MQL5 Code:     Copyright � 2010,   Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
//---- Indicator Version Number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//----three buffers are used for calculation and drawing the indicator
#property indicator_buffers 3
//---- 3 plots are used
#property indicator_plots   3
//+----------------------------------------------+
//|  Parameters of drawing the AMA line          |
//+----------------------------------------------+
//---- drawing indicator 1 as line
#property indicator_type1   DRAW_LINE
//---- blue-violet color is used as the color of the bullish line of the indicator
#property indicator_color1  BlueViolet
//---- line of the indicator 1 is a solid one
#property indicator_style1  STYLE_SOLID
//---- thickness of line of the indicator 1 is equal to 3
#property indicator_width1  3
//---- bullish indicator label display
#property indicator_label1  "AMA"
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- red color is used as the color of the bearish indicator
#property indicator_color2  Red
//---- thickness of line of the indicator 2 is equal to 2
#property indicator_width2  2
//---- bearish indicator label display
#property indicator_label2  "Dn_Signal"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_ARROW
//---- lime color is used as the color of the bullish indicator
#property indicator_color3  Lime
//---- thickness of line of the indicator 3 is equal to 2
#property indicator_width3  2
//---- bullish indicator label display
#property indicator_label3  "Up_Signal"
//+----------------------------------------------+
//| Input parameters of the indicator            |
//+----------------------------------------------+
input int ama_period=9; // Period of AMA
input int fast_ma_period=2; // Period of fast MA
input int slow_ma_period=30; // Period of slow MA
input double G=2.0; // The power the smoothing constant is raised to
input int AMAShift = 0; // Horizontal shift of the indicator in bars
input double dK = 1.0;  //Coefficient for the filter
//+----------------------------------------------+
//---- declaration of dynamic arrays that further
// will be used as indicator buffers
double AMABuffer[];
double BearsBuffer[];
double BullsBuffer[];
//---- declaration of the variables with the floating point for constants
double dSC,slowSC,fastSC; int AMA_Handle,dAMA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- transformation of the dynamic array AMABuffer into an indicator buffer
   SetIndexBuffer(0,AMABuffer,INDICATOR_DATA);
//---- performing the horizontal shift of the indicator 1 by ama_shift
   PlotIndexSetInteger(0,PLOT_SHIFT,AMAShift);
//---- performing shift of the beginning of counting of drawing the indicator 1 by 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ama_period+1);
//--- create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"AMA");
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- transformation of the BearsBuffer dynamic array into an indicator buffer
   SetIndexBuffer(1,BearsBuffer,INDICATOR_DATA);
//---- performing the horizontal shift of the indicator 2 by ama_shift
   PlotIndexSetInteger(1,PLOT_SHIFT,AMAShift);
//---- performing shift of the beginning of drawing the indicator 2 by ama_period + 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ama_period+2);
//--- create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"DnSignal");
//---- selecting symbol for drawing
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);

//---- transformation of the dynamic array BullsBuffer into an indicator buffer
   SetIndexBuffer(2,BullsBuffer,INDICATOR_DATA);
//---- performing the horizontal shift of the indicator 3 by ama_shift
   PlotIndexSetInteger(2,PLOT_SHIFT,AMAShift);
//---- performing shift of the beginning of drawing the indicator 3 by ama_period + 2
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ama_period+2);
//--- create label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"UpSignal");
//---- selecting symbol for drawing
   PlotIndexSetInteger(2,PLOT_ARROW,159);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);

//---- Initialization of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,
                     "AMkA( ",ama_period,", ",fast_ma_period,", ",slow_ma_period," )");
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);

//---- initialization of constants
   slowSC = (2.0 / (slow_ma_period + 1));
   fastSC = (2.0 / (fast_ma_period + 1));
   dSC=fastSC-slowSC;
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const int begin,          // number of beginning of reliable counting of bars
                const double &price[]     // price array for calculation of the indicator
                )
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<2*ama_period+2+begin) return(0);

//---- declaration of local variables
   int first,bar,iii;
   double noise,AMA,signal,ER,ERSC,SSC,price0,price1;
   double Sum,SMAdif,StDev,BULLS,BEARS,Filter;
   static double dAMA[],dama;

//---- calculation of the starting number 'first' for the cycle of recalculation of bars
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=ama_period+2+begin; // starting number for calculation of all bars
      AMA=price[first-1];
      if(ArrayResize(dAMA,ama_period)!=ama_period) return(0);

      //---- increase the position of the beginning of data by 'begin' bars as a result of calculation using data of another indicator
      if(begin>0)
        {
         PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ama_period+begin);
         PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,2*ama_period+begin+2);
         PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,2*ama_period+begin+2);
        }
     }
   else
     {
      first=prev_calculated-1; // starting number for calculation of new bars
      AMA=AMABuffer[first-1];
     }

//---- main cycle of calculation of the AMA indicator
   for(bar=first; bar<rates_total; bar++)
     {
      //----
      noise=Point()/10000;
      for(iii=0; iii<ama_period; iii++)
        {
         price0 = price[bar - iii - 0];
         price1 = price[bar - iii - 1];
         noise += MathAbs(price0 - price1);
        }

      price0 = price[bar];
      price1 = price[bar - ama_period];
      signal = MathAbs(price0 - price1);
      ER=signal/noise;
      ERSC= ER * dSC;
      SSC = ERSC + slowSC;
      AMA = AMA + (MathPow(SSC, G) * (price0 - AMA));
      //AMA = NormalizeDouble(AMA, _Digits);

      //---- Initialization of a cell of the indicator buffer with the received value of AMA
      AMABuffer[bar]=AMA;
     }

   if(prev_calculated==0)
      first=2*ama_period+6+begin;

//---- main cycle of calculation of the AMkA indicator
   for(bar=first; bar<rates_total; bar++)
     {
      //---- loading increments of the AMA indicator for intermediate calculations
      for(iii=0; iii<ama_period; iii++)
         dAMA[iii]=AMABuffer[bar-iii-0]-AMABuffer[bar-iii-1];

      //---- calculating simple average of increments of AMA
      Sum=0.0;
      for(iii=0; iii<ama_period; iii++)
         Sum+=dAMA[iii];
      SMAdif=Sum/ama_period;

      //---- calculating sum of  squared differences of increments and the average
      Sum=0.0;
      for(iii=0; iii<ama_period; iii++)
         Sum+=MathPow(dAMA[iii]-SMAdif,2);

      //---- calculating the total value of the standard deviation StDev from the increment of AMA
      StDev=MathSqrt(Sum/ama_period);

      //---- initialization of variables
      dama=NormalizeDouble(dAMA[0],_Digits+2);
      Filter= NormalizeDouble(dK * StDev,_Digits+2);
      BEARS = 0;
      BULLS = 0;

      //---- calculation of the indicator values
      if(dama < -Filter) BEARS = AMABuffer[bar]; //there is a downward trend
      if(dama > +Filter) BULLS = AMABuffer[bar]; //there is a rising trend

      //---- initialization of cells of the indicator buffers with obtained values
      BullsBuffer[bar] = BULLS;
      BearsBuffer[bar] = BEARS;
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
