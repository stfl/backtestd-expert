//------------------------------------------------------------------
#property copyright   "© mladen, 2016, MetaQuotes Software Corp."
#property link        "www.forex-tsd.com, www.mql5.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   4
#property indicator_label1  "qwma zone"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrGainsboro
#property indicator_label2  "qwma middle"
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_DOT
#property indicator_color2  clrGray
#property indicator_label3  "qwma original"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGray
#property indicator_label4  "qwma"
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrDarkGray,clrLimeGreen,clrDarkOrange
#property indicator_width4  3

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
enum chgColor
{
   chg_onSlope,  // change color on slope change
   chg_onLevel,  // Change color on outer levels cross
   chg_onMiddle, // Change color on middle level crossddk
   chg_onQwma    // Change color on QWMA original cross
};
input ENUM_TIMEFRAMES TimeFrame        = PERIOD_CURRENT; // Time frame
input int             MaPeriod         = 25;             // MA period
input double          MaSpeed          =  2;             // MA "speed"
input enPrices        MaPrice          = pr_close;       // Average price
input int             CorrectionPeriod =  0;             // Deviations period (<1 same as ma period, -1 no correction)
input chgColor        ColorOn          = chg_onLevel;    // Color change on :
input int             FlPeriod         = 25;             // Period for finding floating levels
input double          FlUp             = 90;             // Upper level %
input double          FlDown           = 10;             // Lower level %
 bool            AlertsOn         = false;          // Turn alerts on?
 bool            AlertsOnCurrent  = true;           // Alert on current bar?
 bool            AlertsMessage    = true;           // Display messageas on alerts?
 bool            AlertsSound      = false;          // Play sound on alerts?
 bool            AlertsEmail      = false;          // Send email on alerts?
 bool            AlertsNotify     = false;          // Send push notification on alerts?
 bool            Interpolate      = true;           // Interpolate when in multi time frame mode?

double qwma[],qwmac[],mid[],fup[],fdn[],count[],work[];
int     _mtfHandle = INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),PERIOD_CURRENT,MaPeriod,MaSpeed,MaPrice,CorrectionPeriod,ColorOn,FlPeriod,FlUp,FlDown,AlertsOn,AlertsOnCurrent,AlertsMessage,AlertsSound,AlertsEmail,AlertsNotify)

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,fup  ,INDICATOR_DATA);
   SetIndexBuffer(1,fdn  ,INDICATOR_DATA);
   SetIndexBuffer(2,mid  ,INDICATOR_DATA);
   SetIndexBuffer(3,work ,INDICATOR_DATA);
   SetIndexBuffer(4,qwma ,INDICATOR_DATA);
   SetIndexBuffer(5,qwmac,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,count,INDICATOR_CALCULATIONS);
         timeFrame = MathMax(_Period,TimeFrame);
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(timeFrame)+" qwma floating levels ("+(string)MaPeriod+","+(string)MaSpeed+")");
   return(0);
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
   
      if (timeFrame!=_Period)
      {
         double result[]; datetime currTime[],nextTime[]; 
            if (!timeFrameCheck(timeFrame,time))         return(0);
            if (_mtfHandle==INVALID_HANDLE) _mtfHandle = _mtfCall;
            if (_mtfHandle==INVALID_HANDLE)              return(0);
            if (CopyBuffer(_mtfHandle,6,0,1,result)==-1) return(0); 
      
                //
                //
                //
                //
                //
              
                #define _mtfRatio PeriodSeconds(timeFrame)/PeriodSeconds(_Period)
                int k,n,i = MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0));
                for (; i<rates_total && !_StopFlag; i++ )
                {
                  #define _mtfCopy(_buff,_buffNo) if (CopyBuffer(_mtfHandle,_buffNo,time[i],1,result)==-1) break; _buff[i] = result[0]
                          _mtfCopy(fup  ,0);
                          _mtfCopy(fdn  ,1);
                          _mtfCopy(mid  ,2);
                          _mtfCopy(work ,3);
                          _mtfCopy(qwma ,4);
                          _mtfCopy(qwmac,5);
                   
                          //
                          //
                          //
                          //
                          //
                   
                          #define _mtfInterpolate(_buff) _buff[i-k] = _buff[i]+(_buff[i-n]-_buff[i])*k/n
                          if (!Interpolate) continue;  CopyTime(_Symbol,timeFrame,time[i  ],1,currTime); 
                              if (i<(rates_total-1)) { CopyTime(_Symbol,timeFrame,time[i+1],1,nextTime); if (currTime[0]==nextTime[0]) continue; }
                              for(n=1; (i-n)> 0 && time[i-n] >= currTime[0]; n++) continue;	
                              for(k=1; (i-k)>=0 && k<n; k++)
                              {
                                  _mtfInterpolate(fup);
                                  _mtfInterpolate(fdn);
                                  _mtfInterpolate(mid);
                                  _mtfInterpolate(work);
                                  _mtfInterpolate(qwma);
                              }                                 
                }
                return(i);
      }
   
   //
   //
   //
   //
   //
   
   int colorOn          = (FlPeriod>1) ? ColorOn : chg_onSlope;
   int deviationsPeriod = (CorrectionPeriod>0) ? CorrectionPeriod : (CorrectionPeriod<0) ? 0 : MaPeriod ;
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
   {
      double price = getPrice(MaPrice,open,close,high,low,i,rates_total);
             work[i] = iQwma(price,MaPeriod,MaSpeed,i,rates_total);
               double v1 =         MathPow(iDeviation(price,deviationsPeriod,false,i,rates_total),2);
               double v2 = (i>0) ? MathPow(qwma[i-1]-work[i],2) : 0;
               double c  = (v2<v1||v2==0) ? 0 : 1-v1/v2;
             qwma[i] = (i>0) ? qwma[i-1] + c*(work[i]-qwma[i-1]) : work[i];
             
         
         //
         //
         //
         //
         //
                  
            int    start = MathMax(i-FlPeriod+1,0);
            double min   = qwma[ArrayMinimum(qwma,start,FlPeriod)];
            double max   = qwma[ArrayMaximum(qwma,start,FlPeriod)];
            double range = max-min;
                  fup[i] = min+FlUp  *range/100.0;
                  fdn[i] = min+FlDown*range/100.0;
                  mid[i] = (fup[i]+fdn[i])*0.5;
                  
            switch (colorOn)
            {
               case chg_onLevel :  qwmac[i] = (qwma[i]>fup[i])  ? 1 : (qwma[i]<fdn[i])  ? 2 : (i>0) ? (qwma[i]==qwma[i-1]) ? qwmac[i-1] : 0 : 0; break;
               case chg_onMiddle : qwmac[i] = (qwma[i]>mid[i])  ? 1 : (qwma[i]<mid[i])  ? 2 : (i>0) ? (qwma[i]==qwma[i-1]) ? qwmac[i-1] : 0 : 0; break;
               case chg_onQwma   : qwmac[i] = (qwma[i]<work[i]) ? 1 : (qwma[i]>work[i]) ? 2 : (i>0) ? (qwma[i]==qwma[i-1]) ? qwmac[i-1] : 0 : 0; break;
               default :           qwmac[i] = (i>0) ? (qwma[i]>qwma[i-1]) ? 1 : (qwma[i]<qwma[i-1]) ? 2 : (qwma[i]==qwma[i-1]) ? qwmac[i-1] : 0 : 0;
            }                  
   }
   count[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
   manageAlerts(time,qwmac,rates_total);
   return(rates_total);
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

void manageAlerts(const datetime& _time[], double& _trend[], int bars)
{
   if (AlertsOn)
   {
      int whichBar = bars-1; if (!AlertsOnCurrent) whichBar = bars-2; datetime time1 = _time[whichBar];
      if (_trend[whichBar] != _trend[whichBar-1])
      {
         string add = "slope changed to";
         switch (ColorOn)
         {
            case chg_onLevel  : add = "outer level crossed"; break;
            case chg_onMiddle : add = "outer middle crossed";
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

      string message = TimeToString(TimeLocal(),TIME_SECONDS)+" "+_Symbol+" qwma floating levels state changed to "+doWhat;
         if (AlertsMessage) Alert(message);
         if (AlertsEmail)   SendMail(_Symbol+" qwma floating levels",message);
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

#define _qwmaInstances 3
double workQwma[][_qwmaInstances];
double iQwma(double price, double period, double speed, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workQwma,0)!= bars) ArrayResize(workQwma,bars);
   
   //
   //
   //
   //
   //
   
   workQwma[r][instanceNo] = price;
      double sumw = MathPow(period,speed);
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = MathPow(period-k,speed);
                sumw  += weight;
                sum   += weight*workQwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
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

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

string getIndicatorName()
{
   string path = MQL5InfoString(MQL5_PROGRAM_PATH);
   string data = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Indicators\\";
   string name = StringSubstr(path,StringLen(data));
      return(name);
}

//
//
//
//
//

int    _tfsPer[]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
string _tfsStr[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes","15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours","12 hours","daily","weekly","monthly"};
string timeFrameToString(int period)
{
   if (period==PERIOD_CURRENT) 
       period = _Period;   
         int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);   
}

//
//
//
//
//

bool timeFrameCheck(ENUM_TIMEFRAMES _timeFrame,const datetime& time[])
{
   static bool warned=false;
   if (time[0]<SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE))
   {
      datetime startTime,testTime[]; 
         if (SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,startTime))
         if (startTime>0)                       { CopyTime(_Symbol,_timeFrame,time[0],1,testTime); SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE,startTime); }
         if (startTime<=0 || startTime>time[0]) { Comment(MQL5InfoString(MQL5_PROGRAM_NAME)+"\nMissing data for "+timeFrameToString(_timeFrame)+" time frame\nRe-trying on next tick"); warned=true; return(false); }
   }
   if (warned) { Comment(""); warned=false; }
   return(true);
}