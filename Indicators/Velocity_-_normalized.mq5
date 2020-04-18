//------------------------------------------------------------------
#property copyright "© mladen, 2016, MetaQuotes Software Corp."
#property link      "www.forex-tsd.com, www.mql5.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   5

#property indicator_label1  "velocity OB/OS zone"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'209,243,209',C'255,230,183'
#property indicator_label2  "velocity up level"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_DOT
#property indicator_label3  "velocity middle level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DOT
#property indicator_label4  "velocity down level"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrOrange
#property indicator_style4  STYLE_DOT
#property indicator_label5  "velocity"
#property indicator_type5   DRAW_COLOR_LINE
#property indicator_color5  clrSilver,clrLimeGreen,clrOrange
#property indicator_width5  2
  

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
   cc_onSlope,   // Change color on slope change
   cc_onMiddle,  // Change color on middle line cross
   cc_onLevels   // Change color on outer levels cross
};
enum enNormMethod
{
   nm_atr,  // Use ATR for normalization
   nm_std,  // Use standard deviation without sample correction
   nm_stc,  // Use standard deviation with sample correction
   nm_non   // No normalization
};
input ENUM_TIMEFRAMES TimeFrame       = PERIOD_CURRENT; // Time frame
input int             VelPeriod       = 32;             // Velocity period
input enPrices        VelPrice        = pr_close;       // Price to use
input enNormMethod    NormMethod      = nm_atr;         // Normalization method
input enColorOn       ColorOn         = cc_onLevels;    // Color change :
input int             MinMaxPeriod    = 50;             // Floating levels period (<= 1 to use velocity period)
input double          LevelUp         = 80.0;           // Up level %
input double          LevelDown       = 20.0;           // Down level %
input bool            alertsOn        = false;          // Turn alerts on?
input bool            alertsOnCurrent = true;           // Alert on current bar?
input bool            alertsMessage   = true;           // Display messageas on alerts?
input bool            alertsSound     = false;          // Play sound on alerts?
input bool            alertsEmail     = false;          // Send email on alerts?
input bool            alertsNotify    = false;          // Send push notification on alerts?
input bool            Interpolate     = true;           // Interpolate mtf data ?


double vel[],velc[],fill1[],fill2[],levelUp[],levelMi[],levelDn[],count[];
int     _mtfHandle = INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),PERIOD_CURRENT,VelPeriod,VelPrice,NormMethod,ColorOn,MinMaxPeriod,LevelUp,LevelDown,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify)

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
   SetIndexBuffer(0,fill1  ,INDICATOR_DATA);
   SetIndexBuffer(1,fill2  ,INDICATOR_DATA);
   SetIndexBuffer(2,levelUp,INDICATOR_DATA);
   SetIndexBuffer(3,levelMi,INDICATOR_DATA);
   SetIndexBuffer(4,levelDn,INDICATOR_DATA);
   SetIndexBuffer(5,vel    ,INDICATOR_DATA);
   SetIndexBuffer(6,velc   ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(7,count  ,INDICATOR_CALCULATIONS);
      for (int i=0; i<4; i++) PlotIndexSetInteger(i,PLOT_SHOW_DATA,false);
            timeFrame = MathMax(_Period,TimeFrame);
               if (timeFrame != _Period) _mtfHandle = _mtfCall;
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(timeFrame)+" ATR normalzed velocity ("+(string)VelPeriod+","+(string)MinMaxPeriod+")");
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
            if (_mtfHandle==INVALID_HANDLE) _mtfHandle = _mtfCall;
            if (_mtfHandle==INVALID_HANDLE)              return(0);
            if (CopyBuffer(_mtfHandle,7,0,1,result)==-1) return(0); 
      
                //
                //
                //
                //
                //
              
                #define _mtfRatio PeriodSeconds(timeFrame)/PeriodSeconds(_Period)
                int i,limit = MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0));
                for (i=limit; i<rates_total && !_StopFlag; i++ )
                {
                   if (CopyBuffer(_mtfHandle,0,time[i],1,result)==-1) break; fill1[i]   = result[0];
                   if (CopyBuffer(_mtfHandle,1,time[i],1,result)==-1) break; fill2[i]   = result[0];
                   if (CopyBuffer(_mtfHandle,2,time[i],1,result)==-1) break; levelUp[i] = result[0];
                   if (CopyBuffer(_mtfHandle,3,time[i],1,result)==-1) break; levelMi[i] = result[0];
                   if (CopyBuffer(_mtfHandle,4,time[i],1,result)==-1) break; levelDn[i] = result[0];
                   if (CopyBuffer(_mtfHandle,5,time[i],1,result)==-1) break; vel[i]     = result[0];
                   if (CopyBuffer(_mtfHandle,6,time[i],1,result)==-1) break; velc[i]    = result[0];
                   
                   //
                   //
                   //
                   //
                   //
                   
                   #define _interpolate(buff,i,k,n) buff[i-k] = buff[i]+(buff[i-n]-buff[i])*k/n
                   if (!Interpolate) continue; CopyTime(_Symbol,TimeFrame,time[i  ],1,currTime); 
                      if (i<(rates_total-1)) { CopyTime(_Symbol,TimeFrame,time[i+1],1,nextTime); if (currTime[0]==nextTime[0]) continue; }
                      int n,k;
                         for(n=1; (i-n)> 0 && time[i-n] >= currTime[0]; n++) continue;	
                         for(k=1; (i-k)>=0 && k<n; k++)
                         {
                            _interpolate(fill1  ,i,k,n);
                            _interpolate(fill2  ,i,k,n);
                            _interpolate(levelUp,i,k,n);
                            _interpolate(levelDn,i,k,n);
                            _interpolate(levelMi,i,k,n);
                            _interpolate(vel    ,i,k,n);
                         }                            
                }     
                if (i!=rates_total) return(0); return(rates_total);
      }

   //
   //
   //
   //
   //

   int minMaxPeriod = (MinMaxPeriod>0) ? MinMaxPeriod : VelPeriod;
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !_StopFlag; i++)
   {
      double price = getPrice(VelPrice,open,close,high,low,i,rates_total), div=0;
            switch (NormMethod)
            {
               case nm_atr : div = iAtr(VelPeriod,high,low,close,i); break;
               case nm_non : div = 1;                                break;
               default :     div = iDeviation(price,VelPeriod,NormMethod==nm_stc,i,rates_total);
            }                                    
            vel[i] = (div!=0) ? iMomentumS(price,VelPeriod,1,2,i,rates_total)/div : iMomentumS(price,VelPeriod,1,2,i,rates_total);
            double min = vel[i], max = vel[i];
            for (int k=1; k<minMaxPeriod && i-k>=0; k++)
            {
                  min = MathMin(vel[i-k],min);
                  max = MathMax(vel[i-k],max);
            }
            double range = max-min;
            levelUp[i] = min+LevelUp  *range/100.0;
            levelDn[i] = min+LevelDown*range/100.0;
            levelMi[i] = min+0.5*range;
            switch(ColorOn)
            {
               case cc_onLevels: velc[i] = (vel[i]>levelUp[i])  ? 1 : (vel[i]<levelDn[i])  ? 2 : 0; break;
               case cc_onMiddle: velc[i] = (vel[i]>levelMi[i])  ? 1 : (vel[i]<levelMi[i])  ? 2 : 0; break;
               default :         velc[i] = (i>0) ? (vel[i]>vel[i-1]) ? 1 : (vel[i]<vel[i-1]) ? 2 : 0 : 0;
            }                  
      fill1[i] = vel[i];
      fill2[i] = (vel[i]>levelUp[i]) ? levelUp[i] : (vel[i]<levelDn[i]) ? levelDn[i] : vel[i];
   }
   count[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
   manageAlerts(time,velc,rates_total);
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

double iAtr(int atrPeriod, const double& high[],  const double& low[], const double& close[], int i)
{
   double atr=0;
   for (int k=0; k<atrPeriod && i-k>=0; k++)
      if (i-k==0)
            atr += high[i-k]+low[i-k];
      else  atr += MathMax(high[i-k],close[i-k-1])-MathMin(low[i-k],close[i-k-1]);
   return(atr/atrPeriod);
}

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

void manageAlerts(const datetime& time[], double& ttrend[], int bars)
{
   if (!alertsOn) return;
      int whichBar = bars-1; if (!alertsOnCurrent) whichBar = bars-2; datetime time1 = time[whichBar];
      if (ttrend[whichBar] != ttrend[whichBar-1])
      {
         if (ttrend[whichBar] == 1) doAlert(time1,"up");
         if (ttrend[whichBar] == 2) doAlert(time1,"down");
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

      string message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" velocity state changed to "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" velocity",message);
         if (alertsNotify)  SendNotification(message);
         if (alertsSound)   PlaySound("alert2.wav");
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

double workMom[];
double iMomentumS(double price, double length, double powSlow, double powFast, int i, int bars)
{
   if (ArraySize(workMom)!=bars) ArrayResize(workMom,bars);  workMom[i] = price;
      
      //
      //
      //
      //
      //
      
      double suma = 0.0, sumwa=0;
      double sumb = 0.0, sumwb=0;
         for(int k=0; k<length && (i-k)>=0; k++)
         {
            double weight = length-k;
               suma  += workMom[i-k] * MathPow(weight,powSlow);
               sumb  += workMom[i-k] * MathPow(weight,powFast);
               sumwa += MathPow(weight,powSlow);
               sumwb += MathPow(weight,powFast);
         }
   return(sumb/sumwb-suma/sumwa);
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

#define priceInstances 1
double workHa[][priceInstances*4];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i,int _bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) ArrayResize(workHa,_bars); instanceNo*=4;
         
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


//------------------------------------------------------------------
//
//------------------------------------------------------------------
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
         int i; for(i=ArraySize(_tfsPer)-1;i>=0;i--) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);   
}