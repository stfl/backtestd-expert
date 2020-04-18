//+------------------------------------------------------------------+
//|                                                         YGMA.mq5 |
//|                                                     Yuriy Tokman |
//|                                                http://ytg.com.ua |
//+------------------------------------------------------------------+
#property copyright "Yuriy Tokman"
#property link      "http://ytg.com.ua"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots   2
#property indicator_width1   2
#property indicator_width2   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_color2  clrLime
//--- input parameters
input int            YMA_Period=5;
input int            GMA_Period=12;
//--- indicator buffers
double Buffer[],Buffer2[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,Buffer);
   SetIndexBuffer(1,Buffer2);   
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,MathMax(YMA_Period,GMA_Period));
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,MathMax(YMA_Period,GMA_Period));   
   string short_name="YGMA";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   PlotIndexSetString(0,PLOT_LABEL,"YMA");
   PlotIndexSetString(1,PLOT_LABEL,"GMA");    
//---
   return(INIT_SUCCEEDED);
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
//----
   int i,limit;
//--- check for rates
   if(rates_total<MathMax(YMA_Period,GMA_Period)) return(0);
//--- preliminary calculations
   if(prev_calculated==0)limit=MathMax(YMA_Period,GMA_Period);
   else limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      double MA = ma (open,high,low,close,i);      
      Buffer[i]=MA;     
      double MG = mg (open,high,low,close,i);      
      Buffer2[i]=MG;
     }
 //----
   return(rates_total);
  }
//+------------------------------------------------------------------+
 double ma (const double &o[],const double &h[],const double &l[],const double &c[],int _i)
  {
   double res=0;
   for(int j=_i;j>_i-YMA_Period && j>0;j--)
   res += (c[j]+o[j]+h[j]+l[j])/4.0;   
   return(res/YMA_Period); 
  }
//----
 double mg (const double &o[],const double &h[],const double &l[],const double &c[],int _i)
  {
   double res =1;
   for(int j=_i;j>_i-GMA_Period && j>0;j--)
   res *= (c[j]+o[j]+h[j]+l[j])/4.0;
   return(MathPow(res,1.0/GMA_Period));  
  }
//----