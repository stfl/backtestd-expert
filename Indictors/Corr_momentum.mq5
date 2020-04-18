//------------------------------------------------------------------
#property copyright "© mladen, 2016, MetaQuotes Software Corp."
#property link      "www.forex-tsd.com, www.mql5.com"
#property version   "1.00"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   6
#property indicator_label1  "corrected momentum levels"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrLimeGreen,clrOrange
#property indicator_label2  "corrected momentum up level"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_DOT
#property indicator_label3  "corrected momentum middle level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DOT
#property indicator_label4  "corrected momentum down level"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrOrange
#property indicator_style4  STYLE_DOT
#property indicator_label5  "momentum"
#property indicator_type5   DRAW_COLOR_LINE
#property indicator_color5  clrDarkGray,clrLimeGreen,clrSandyBrown
#property indicator_style5  STYLE_DOT
#property indicator_label6  "corrected momentum"
#property indicator_type6   DRAW_COLOR_LINE
#property indicator_color6  clrDarkGray,clrLimeGreen,clrSandyBrown
#property indicator_width6  2

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};
enum enColorOn
{
   chg_onSlope,  // change color on slope change
   chg_onLevel,  // Change color on outer levels cross
   chg_onMiddle, // Change color on middle level cross
   chg_onOrig    // Change color on momentum value cross
};

input int        MomPeriod        = 32;          // Momentum period
input int        CorrectionPeriod =  0;          // Correction period (<0 no correction =0 same as momentum period)
input enPrices   Price            = pr_close;    // Price
input enColorOn  ColorOn          = chg_onLevel; // Color change on :
input int        LevelsPeriod     = 25;          // Levels period
input double     LevelsUp         = 90;          // Upper level %
input double     LevelsDown       = 10;          // Lower level %
input bool       AlertsOn         = false;       // Turn alerts on?
input bool       AlertsOnCurrent  = true;        // Alert on current bar?
input bool       AlertsMessage    = true;        // Display messageas on alerts?
input bool       AlertsSound      = false;       // Play sound on alerts?
input bool       AlertsEmail      = false;       // Send email on alerts?
input bool       AlertsNotify     = false;       // Send push notification on alerts?

double  val[],valc[],fill1[],fill2[],levelUp[],levelMi[],levelDn[],cor[],corc[],prices[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void OnInit()
{
   SetIndexBuffer(0,fill1  ,INDICATOR_DATA);
   SetIndexBuffer(1,fill2  ,INDICATOR_DATA);
   SetIndexBuffer(2,levelUp,INDICATOR_DATA);
   SetIndexBuffer(3,levelMi,INDICATOR_DATA);
   SetIndexBuffer(4,levelDn,INDICATOR_DATA);
   SetIndexBuffer(5,val    ,INDICATOR_DATA);
   SetIndexBuffer(6,valc   ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(7,cor    ,INDICATOR_DATA);
   SetIndexBuffer(8,corc   ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(9,prices ,INDICATOR_CALCULATIONS);
      IndicatorSetString(INDICATOR_SHORTNAME,"\"Corrected\" momentum ("+(string)MomPeriod+","+(string)CorrectionPeriod+","+(string)LevelsPeriod+")");
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   if (Bars(_Symbol,_Period)<rates_total) return(-1);
   
   //
   //
   //
   //
   //
   
   int deviationsPeriod = (CorrectionPeriod>0) ? CorrectionPeriod : (CorrectionPeriod<0) ? 0 : MomPeriod ;
   int colorOn          = (deviationsPeriod>0) ? ColorOn : (ColorOn!=chg_onOrig) ? ColorOn : chg_onSlope;
   int levelPeriod      = (LevelsPeriod>1) ? LevelsPeriod : MomPeriod; 
   int i=(int)MathMax(prev_calculated-1,0); for (; i<rates_total && !_StopFlag; i++)
   {
      prices[i] = getPrice(Price,open,close,high,low,i,rates_total);
      val[i]    = prices[i]-prices[MathMax(i-MomPeriod,0)];
         double v1 =         MathPow(iDeviation(val[i],deviationsPeriod,false,i,rates_total),2);
         double v2 = (i>0) ? MathPow(cor[i-1]-val[i],2) : 0;
         double c  = (v2<v1 || v2==0) ? 0 : 1-v1/v2;
      cor[i] = (i>0) ? cor[i-1]+c*(val[i]-cor[i-1]) : val[i];
            
      //
      //
      //
      //
      //
            
         int    start = MathMax(i-levelPeriod+1,0);
         double min   = cor[ArrayMinimum(cor,start,levelPeriod)];
         double max   = cor[ArrayMaximum(cor,start,levelPeriod)];
         double range = max-min;
            levelUp[i] = min+LevelsUp  *range/100.0;
            levelDn[i] = min+LevelsDown*range/100.0;
            levelMi[i] = (levelUp[i]+levelDn[i])*0.5;
            valc[i]  = (i>0) ? (val[i]>val[i-1]) ? 1 : (val[i]<val[i-1]) ? 2 : valc[i-1]: 0;
            switch (colorOn)
            {
               case chg_onOrig :   corc[i] = (cor[i]<val[i])     ? 1 : (cor[i]>val[i])     ? 2 : (i>0) ? corc[i-1]: 0; break;
               case chg_onMiddle : corc[i] = (cor[i]>levelMi[i]) ? 1 : (cor[i]<levelMi[i]) ? 2 : (i>0) ? corc[i-1]: 0; break;
               case chg_onLevel:   corc[i] = (cor[i]>levelUp[i]) ? 1 : (cor[i]<levelDn[i]) ? 2 : (i>0) ? (cor[i]==cor[i-1]) ? corc[i-1]: 0 : 0; break;
               default :           corc[i] = (i>0) ? (cor[i]>cor[i-1]) ? 1 : (cor[i]<cor[i-1]) ? 2 : corc[i-1]: 0;
            }               
            fill2[i] = (cor[i]>levelUp[i]) ? levelUp[i] : (cor[i]<levelDn[i]) ? levelDn[i] : cor[i];
            fill1[i] = cor[i];
   }         
   manageAlerts(time,corc,colorOn,rates_total);
   return(i);
}


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void manageAlerts(const datetime& _time[], double& _trend[], int colorOn, int bars)
{
   if (AlertsOn)
   {
      int whichBar = bars-1; if (!AlertsOnCurrent) whichBar = bars-2; datetime time1 = _time[whichBar];
      if (_trend[whichBar] != _trend[whichBar-1])
      {
         string add = "slope changed to";
         switch (colorOn)
         {
            case chg_onLevel  : add = "outer level crossed";  break;
            case chg_onMiddle : add = "middle level crossed"; break;
            case chg_onOrig   : add = "momentum value crossed";
         }                  
         if (_trend[whichBar] == 1) doAlert(time1,add+" up");
         if (_trend[whichBar] == 2) doAlert(time1,add+" down");
      }         
   }
}   

//
//
//
//
//

void doAlert(datetime forTime, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      string message = TimeToString(TimeLocal(),TIME_SECONDS)+" "+_Symbol+" corrected momentum "+doWhat;
         if (AlertsMessage) Alert(message);
         if (AlertsEmail)   SendMail(_Symbol+" corrected momentum",message);
         if (AlertsNotify)  SendNotification(message);
         if (AlertsSound)   PlaySound("alert2.wav");
   }
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
// 
//
//
//
//

double workDev[];
double iDeviation(double value, int length, bool isSample, int i, int bars)
{
   if (ArraySize(workDev)!=bars) ArrayResize(workDev,bars); workDev[i] = value;
                 
   //
   //
   //
   //
   //
   
      double oldMean   = value;
      double newMean   = value;
      double squares   = 0; int k;
      for (k=1; k<length && (i-k)>=0; k++)
      {
         newMean  = (workDev[i-k]-oldMean)/(k+1)+oldMean;
         squares += (workDev[i-k]-oldMean)*(workDev[i-k]-newMean);
         oldMean  = newMean;
      }
      return(MathSqrt(squares/MathMax(k-isSample,1)));
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//

#define _pricesInstances 1
#define _pricesSize      4
double workHa[][_pricesInstances*_pricesSize];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i,int _bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) ArrayResize(workHa,_bars); instanceNo*=_pricesSize;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
   }
   return(0);
}