//+------------------------------------------------------------------+
//|                                                Aroon Up and Down |
//|                                 Copyright © 2009-2016, EarnForex |
//|                                        http://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2016, EarnForex"
#property link      "http://www.earnforex.com"
#property version   "1.02"
#property description "Aroon Up Down - local top and bottom indicator."
#property description "Helps to buy from the bottom and sell from the top."

//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_color1  clrDodgerBlue
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_color2  clrRed
#property indicator_minimum 0

//---- indicator parameters
input int AroonPeriod = 14;
bool MailAlert = false;  //Alerts will be mailed to address set in MT5 options
bool SoundAlert = false; //Alerts will sound on indicator cross

//---- indicator buffers
double AroonUpBuffer[];
double AroonDnBuffer[];

int LastBars = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "Aroon Up Down" + IntegerToString(AroonPeriod));

   SetIndexBuffer(0, AroonUpBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, AroonDnBuffer, INDICATOR_DATA);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 200);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 200);

   IndicatorSetInteger(INDICATOR_DIGITS, 1);
}

//+------------------------------------------------------------------+
//| Aroon Up & Dn                                                    |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &High[],
                const double &Low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int      ArPer, limit, i;     
   int      UpBarDif, DnBarDif;
   int      counted_bars = prev_calculated;

   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Low, true);
   
   ArPer = AroonPeriod;
   
   //---- check for possible errors
   if (counted_bars < 0) return(-1);
   if (ArPer < 1) return(-1);      

   //---- last counted bar will be recounted
   if (counted_bars > 0) counted_bars--;
   limit = rates_total - counted_bars;

   //----Calculation---------------------------
   for (i = 0; i < limit; i++)
   {
  	   int HH = ArrayMaximum(High, i, ArPer);
  	   int LL = ArrayMinimum(Low, i, ArPer);

      UpBarDif = i - HH; //Period substraction
      DnBarDif = i - LL; //Period substraction
      
      AroonUpBuffer[rates_total - i - 1] = 100 + (100.0 / ArPer) * (UpBarDif); //Adjusted Aroon Up
      AroonDnBuffer[rates_total - i - 1] = 100 + (100.0 / ArPer) * (DnBarDif); //Adjusted Aroon Down

      if (LastBars != rates_total)
      {
     	   MqlDateTime dt;
			TimeCurrent(dt);
         if ((AroonUpBuffer[0] > AroonDnBuffer[0]) && (AroonUpBuffer[1] <= AroonDnBuffer[1]))
         {
            if (MailAlert) SendMail("Aroon Up & Down Indicator Alert", "The indicator produced a cross (Blue ABOVE Red) on " + IntegerToString(dt.year) + "-" + IntegerToString(dt.mon) + "-" + IntegerToString(dt.day) + " " + IntegerToString(dt.hour) + ":" + IntegerToString(dt.min));
            if (SoundAlert) Alert("Aroon Up & Down produced a cross (Blue ABOVE Red)");
         }
         else if ((AroonUpBuffer[0] < AroonDnBuffer[0]) && (AroonUpBuffer[1] >= AroonDnBuffer[1]))
         {
            if (MailAlert)	SendMail("Aroon Up & Down Indicator Alert", "The indicator produced a cross (Blue BELOW Red) on " + IntegerToString(dt.year) + "-" + IntegerToString(dt.mon) + "-" + IntegerToString(dt.day) + " " + IntegerToString(dt.hour) + ":" + IntegerToString(dt.min));
            if (SoundAlert) Alert("Aroon Up & Down produced a cross (Blue BELOW Red)");
         }
         LastBars = rates_total;
      }
   }
   
   return(rates_total);
}  