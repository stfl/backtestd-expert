//+------------------------------------------------------------------+
//|                                                          BB MACD |
//|                                 Copyright © 2009-2018, EarnForex |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2018, EarnForex"
#property link      "https://www.earnforex.com/metatrader-indicators/BB-MACD/"
#property version   "1.02"

#property description "An advanced version of MACD indicator for trend change detection."

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   3
#property indicator_color1  clrLime, clrMagenta    // Up/down bullets
#property indicator_type1   DRAW_COLOR_ARROW
#property indicator_style1  STYLE_SOLID
#property indicator_width1  0
#property indicator_label1  "bbMACD"
#property indicator_color2  clrBlue    // Upper band
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label2  "Upper band"
#property indicator_color3  clrRed     // Lower band
#property indicator_type3   DRAW_LINE
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label3  "Lower band"

// Indicator parameters:
input int FastLen = 12;
input int SlowLen = 26;
input int Length = 10;
input int barsCount = 400;
input double StDv = 2.5;
input bool EnableNativeAlerts = false;
input bool EnableSoundAlerts = false;
input bool EnableEmailAlerts = false;
input bool EnablePushAlerts = false;
input string SoundFileName	= "alert.wav";

// Indicator data and color buffers:
double ExtMapBuffer1[]; // bbMACD
double ExtMapBuffer2[]; // bbMACD color
double ExtMapBuffer3[]; // Upper band
double ExtMapBuffer4[]; // Lower band
double ExtMapBuffer5[]; // Data for "iMAOnArray()"

// Indicator calculation buffers:
double MABuff1[];
double MABuff2[];
double bbMACD[];

// Global variables:
int Oldest_bbMACD; // To avoid calculating EMA using bbMACD older than this.
datetime LastAlertTime;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
 	IndicatorSetString(INDICATOR_SHORTNAME, "BB MACD(" + IntegerToString(FastLen) + "," + IntegerToString(SlowLen) + "," + IntegerToString(Length) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);

//---- indicator buffers mapping
   SetIndexBuffer(0, ExtMapBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, ExtMapBuffer2, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, ExtMapBuffer3, INDICATOR_DATA);
   SetIndexBuffer(3, ExtMapBuffer4, INDICATOR_DATA);
   SetIndexBuffer(4, ExtMapBuffer5, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, MABuff1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, MABuff2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, bbMACD, INDICATOR_CALCULATIONS);

   // Set the correct order: 0 is the latest, N - is the oldest.
   ArraySetAsSeries(ExtMapBuffer1, true);
   ArraySetAsSeries(ExtMapBuffer2, true);
   ArraySetAsSeries(ExtMapBuffer3, true);
   ArraySetAsSeries(ExtMapBuffer4, true);
   ArraySetAsSeries(ExtMapBuffer5, true);
   ArraySetAsSeries(MABuff1, true);
   ArraySetAsSeries(MABuff2, true);
   ArraySetAsSeries(bbMACD, true);
   
   PlotIndexSetInteger(0, PLOT_ARROW, 108);
   
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   
   // For barsCount > 0, PLOT_DRAW_BEGIN is calculated in OnCalculate().
   if (barsCount == 0)
   {
      PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, Length);
      PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, Length);
      PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, Length);
   }
   
   Oldest_bbMACD = 0;
   LastAlertTime = 0;
}

//+------------------------------------------------------------------+
//| Custom BB_MACD                                                   |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int limit;

   if (rates_total < Length)
   {
      Print("Not enough bars!");
      return(-1);
   }
   
   int counted_bars = prev_calculated;
   if (counted_bars < 0) return(-1);
   if (counted_bars > 0) counted_bars--;
   
   ArraySetAsSeries(Time, true);
   
   if (barsCount > 0) limit = MathMin(rates_total - counted_bars, barsCount);
   else limit = rates_total - counted_bars;

   // Adjust starting point in time for indicator output.
   if (barsCount > 0)
   {
      int draw_begin = rates_total - barsCount + Length;
      if (draw_begin < Length) draw_begin = Length;
      PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, draw_begin);
      PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, draw_begin);
      PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, draw_begin);
   }

   int myMA = iMA(NULL, 0, FastLen, 0, MODE_EMA, PRICE_CLOSE);
   if (CopyBuffer(myMA, 0, 0, rates_total, MABuff1) != rates_total) return(0);
   myMA = iMA(NULL, 0, SlowLen, 0, MODE_EMA, PRICE_CLOSE);
   if (CopyBuffer(myMA, 0, 0, rates_total, MABuff2) != rates_total) return(0);

   // MA buffers can hold barsCount or even rates_total valid values.
   for (int i = 0; i < limit; i++)
       bbMACD[i] = MABuff1[i] - MABuff2[i];

   if (limit - 1 > Oldest_bbMACD) Oldest_bbMACD = limit - 1;

   // EMA can also be safely calculated on barsCount or even rates_total bars.
   CalculateEMA(limit, Length, bbMACD);
   
   // StdDev will be calculated using Length as a period on the previously calculated EMA data. Avoiding 'array out of range' errors.
   if (barsCount > 0)
      if (limit > barsCount - Length) limit = barsCount - Length;
   if (limit > rates_total - Length) limit = rates_total - Length;

   for (int i = 0; i < limit; i++)
   {
      double avg = ExtMapBuffer5[i]; // MA on Array
		double sDev = StdDevFunc(i, Length, bbMACD); // StdDev on Array
      
      ExtMapBuffer1[i] = bbMACD[i];                             // bbMACD
      if (bbMACD[i] > bbMACD[i + 1]) ExtMapBuffer2[i] = 0;      // Uptrend
      else if (bbMACD[i] < bbMACD[i + 1]) ExtMapBuffer2[i] = 1; // Downtrend
      
      ExtMapBuffer3[i] = avg + (StDv * sDev); // Upper band
      ExtMapBuffer4[i] = avg - (StDv * sDev); // Lower band

      // The last check is needed to make sure the previous value has been calculated already because the values are filled from left to right.
      if ((i == 1) && (LastAlertTime != Time[1]) && (ExtMapBuffer1[i + 1] == bbMACD[i + 1]))
      {
         if ((ExtMapBuffer2[i] == 0) && (ExtMapBuffer2[i + 1] == 1))
         {
      		string Text = Symbol() + " - " + EnumToString((ENUM_TIMEFRAMES)Period()) + " - BB_MACD: from DOWN to UP @ " + TimeToString(Time[i]) + ".";
      		if (EnableNativeAlerts) Alert(Text);
      		if (EnableEmailAlerts) SendMail(Text, Text);
      		if (EnableSoundAlerts) PlaySound(SoundFileName);
      		if (EnablePushAlerts) SendNotification(Text);
      		LastAlertTime = Time[i];
         }
         else if ((ExtMapBuffer2[i] == 1) && (ExtMapBuffer2[i + 1] == 0))
         {
      		string Text = Symbol() + " - " + EnumToString((ENUM_TIMEFRAMES)Period()) + " - BB_MACD: from UP to DOWN @ " + TimeToString(Time[i]) + ".";
      		if (EnableNativeAlerts) Alert(Text);
      		if (EnableEmailAlerts) SendMail(Text, Text);
      		if (EnableSoundAlerts) PlaySound(SoundFileName);
      		if (EnablePushAlerts) SendNotification(Text);
      		LastAlertTime = Time[i];
         }
      }
   }
   return(rates_total);
}

//+------------------------------------------------------------------+
//|  Exponential Moving Average                                      |
//|  Fills the buffer array with EMA values.									|
//+------------------------------------------------------------------+
void CalculateEMA(int begin, int period, const double &price[])
{
   double SmoothFactor = 2.0 / (1.0 + period);
	int start;
	
   // First time.
   if (begin == Oldest_bbMACD + 1)
   {
   	ExtMapBuffer5[Oldest_bbMACD] = price[Oldest_bbMACD];
   	start = Oldest_bbMACD - 1;
   }
   else start = begin;

   for (int i = start; i >= 0; i--) ExtMapBuffer5[i] = price[i] * SmoothFactor + ExtMapBuffer5[i + 1] * (1.0 - SmoothFactor);
}

//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//| Returns StdDev for the given position (bar).                     |
//+------------------------------------------------------------------+
double StdDevFunc(int position, int period, const double &price[])
{
   double dTmp = 0.0;
   for (int i = 0; i < period; i++)	dTmp += MathPow(price[position + i] - ExtMapBuffer5[position], 2);
   dTmp = MathSqrt(dTmp / period);

   return(dTmp);
}
//+------------------------------------------------------------------+