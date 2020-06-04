//------------------------------------------------------------------
#property copyright "© mladen, 2016, MetaQuotes Software Corp."
#property link      "www.forex-tsd.com, www.mql5.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "Laguerre"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGray,clrDeepSkyBlue,clrSandyBrown
#property indicator_width1  3

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
input ENUM_TIMEFRAMES TimeFrame       = PERIOD_CURRENT; // Time frame
input double          LaggPeriod      = 10;             // Laguerre period
input double          LaggSmooth      = 0.5;            // Laguerre "smooth" 
input enPrices        Price           = pr_median;      // Price 
bool            AlertsOn        = false;          // Turn alerts on?
bool            AlertsOnCurrent = false;           // Alert on current bar?
bool            AlertsMessage   = false;           // Display messageas on alerts?
bool            AlertsSound     = false;          // Play sound on alerts?
bool            AlertsEmail     = false;          // Send email on alerts?
bool            AlertsNotify    = false;          // Send push notification on alerts?
bool            Interpolate     = true;           // Interpolate mtf data ?

//
//
//
//
//

double lagg1[],lagg1c[],count[];
int _mtfHandle = INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),PERIOD_CURRENT,LaggPeriod,LaggSmooth,Price,AlertsOn,AlertsOnCurrent,AlertsMessage,AlertsSound,AlertsEmail,AlertsNotify)

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
   SetIndexBuffer(0,lagg1 ,INDICATOR_DATA);
   SetIndexBuffer(1,lagg1c,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,count ,INDICATOR_CALCULATIONS);
         timeFrame = MathMax(_Period,TimeFrame);
   IndicatorSetString(INDICATOR_SHORTNAME,"Adaptive Laguerre ("+(string)LaggPeriod+")");
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
            if (CopyBuffer(_mtfHandle,2,0,1,result)==-1) return(0); 
      
                //
                //
                //
                //
                //
              
                #define _mtfRatio PeriodSeconds(timeFrame)/PeriodSeconds(_Period)
                int i,k,n,limit = MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0));
                for (i=limit; i<rates_total && !_StopFlag; i++ )
                {
                  #define _mtfCopy(_buff,_buffNo) if (CopyBuffer(_mtfHandle,_buffNo,time[i],1,result)==-1) break; _buff[i] = result[0]
                          _mtfCopy(lagg1 ,0);
                          _mtfCopy(lagg1c,1);
                   
                          //
                          //
                          //
                          //
                          //
                   
                          if (!Interpolate) continue;  CopyTime(_Symbol,timeFrame,time[i  ],1,currTime); 
                              if (i<(rates_total-1)) { CopyTime(_Symbol,timeFrame,time[i+1],1,nextTime); if (currTime[0]==nextTime[0]) continue; }
                              for(n=1; (i-n)> 0 && time[i-n] >= currTime[0]; n++) continue;	
                              for(k=1; (i-k)>=0 && k<n; k++)
                                 #define _mtfInterpolate(_buff) _buff[i-k] = _buff[i]+(_buff[i-n]-_buff[i])*k/n
                                         _mtfInterpolate(lagg1);
                }
                return(i);
      }

   //
   //
   //
   //
   //

   int i=MathMax(prev_calculated-1,0); for (; i<rates_total  && !_StopFlag; i++)
   {
      lagg1[i]  = iLaGuerreFilterAdaptive(getPrice(Price,open,close,high,low,i,rates_total),LaggPeriod,LaggSmooth,rates_total,i,0);
      lagg1c[i] = (i>0) ? (lagg1[i]>lagg1[i-1]) ? 1 : (lagg1[i]<lagg1[i-1]) ? 2 :  lagg1c[i-1] : 0;
   }
   count[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
   manageAlerts(time,lagg1c,rates_total);
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

#define _laguerreInstances     1
#define _laguerreInstancesSize 6
#define _filt                  4
#define _diff                  5
double _sortLagf[],_workLagFila[][_laguerreInstances*_laguerreInstancesSize];


double iLaGuerreFilterAdaptive(double price, double period, double smooth, int bars, int i, int instanceNo=0)
{
   int median = (int)MathMax(period*smooth,2); 
      if (ArrayRange(_workLagFila,0)!=bars) ArrayResize(_workLagFila,bars); instanceNo*=_laguerreInstancesSize;
      if (ArraySize(_sortLagf)!=median)     ArrayResize(_sortLagf,median);

      //
      //
      //
      //
      //
         
         _workLagFila[i][instanceNo+_filt] = price;
         _workLagFila[i][instanceNo+_diff] = (i>0) ? MathAbs(price-_workLagFila[i-1][instanceNo+_filt]) : 0;
            double alpha = 0;
            double hi    = _workLagFila[i][instanceNo+_diff];
            double lo    = _workLagFila[i][instanceNo+_diff];
            for (int k=1; k<period && (i-k)>=0; k++) 
            {
               hi = MathMax(hi,_workLagFila[i-k][instanceNo+_diff]);
               lo = MathMin(lo,_workLagFila[i-k][instanceNo+_diff]);
            }
            if (hi!=lo)
            {
               int k=0; for (; k<median && (i-k)>=0; k++) _sortLagf[k] = (_workLagFila[i-k][instanceNo+_diff]-lo)/(hi-lo); for (; k<median; k++) _sortLagf[k]=0;
               ArraySort(_sortLagf);
                  if (MathMod(median,2.0) != 0) alpha =  _sortLagf[median/2];         
                  else                          alpha = (_sortLagf[median/2]+_sortLagf[(median/2)-1])/2.0;
            }
            double gamma = MathMax(MathMin(1.0-alpha,1-DBL_MIN),DBL_MIN);

   //
   //
   //
   //
   //

   if (i>0 && period>1)
   {
      _workLagFila[i][instanceNo+0] = (1.0 - gamma)*price                                                    + gamma*_workLagFila[i-1][instanceNo+0];
      _workLagFila[i][instanceNo+1] = -gamma*_workLagFila[i][instanceNo+0] + _workLagFila[i-1][instanceNo+0] + gamma*_workLagFila[i-1][instanceNo+1];
	   _workLagFila[i][instanceNo+2] = -gamma*_workLagFila[i][instanceNo+1] + _workLagFila[i-1][instanceNo+1] + gamma*_workLagFila[i-1][instanceNo+2];
	   _workLagFila[i][instanceNo+3] = -gamma*_workLagFila[i][instanceNo+2] + _workLagFila[i-1][instanceNo+2] + gamma*_workLagFila[i-1][instanceNo+3];
      _workLagFila[i][instanceNo+_filt] = (_workLagFila[i][instanceNo+0]+2.0*_workLagFila[i][instanceNo+1]+2.0*_workLagFila[i][instanceNo+2]+_workLagFila[i][instanceNo+3])/6.0;
   }
   else for (int k=0; k<=_filt; k++) _workLagFila[i][instanceNo+k] = price;
   return(_workLagFila[i][instanceNo+_filt]);
}


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void manageAlerts(const datetime& atime[], double& atrend[], int bars)
{
   if (!AlertsOn) return;
      int whichBar = bars-1; if (!AlertsOnCurrent) whichBar = bars-2; datetime time1 = atime[whichBar];
      if (atrend[whichBar] != atrend[whichBar-1])
      {
         if (atrend[whichBar] == 1) doAlert(time1,"up");
         if (atrend[whichBar] == 2) doAlert(time1,"down");
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
   string message;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" adaptive Laguerre filter state changed to "+doWhat;
         if (AlertsMessage) Alert(message);
         if (AlertsEmail)   SendMail(_Symbol+" adaptive Laguerre filter",message);
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