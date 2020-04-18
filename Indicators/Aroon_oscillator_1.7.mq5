//------------------------------------------------------------------
#property copyright "© mladen, 2016, MetaQuotes Software Corp."
#property link      "www.forex-tsd.com, www.mql5.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   4
#property indicator_label1  "Aroon"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'209,243,209',C'255,230,183'
#property indicator_label2  "Aroon levels up"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'209,243,209'
#property indicator_label3  "Aroon levels down"
#property indicator_type3   DRAW_LINE
#property indicator_color3  C'255,230,183'
#property indicator_label4  "Aroon oscillator"
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrDarkGray,clrLimeGreen,clrOrange
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_minimum -101
#property indicator_maximum  101

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
#define _fltPrc 0x01
#define _fltVal 0x10
enum enFilterWhat
{
   flt_01=_fltPrc,        // Filter the prices
   flt_02=_fltVal,        // Filter the Aroon oscillator value
   flt_03=_fltPrc+_fltVal // Filter prices and the Aroon oscillator value
};

input ENUM_TIMEFRAMES TimeFrame       = PERIOD_CURRENT; // Time frame
input int             AroonPeriod     = 25;             // Aroon oscillator period
input enPrices        PriceHigh       = pr_high;        // Price to use for high
input enPrices        PriceLow        = pr_low;         // Price to use for low
input int             LevelsPeriod    = 0;              // Levels period (0 to use the same as Arron period)
input double          LevelsUp        = 80;             // Levels up 
input double          LevelsDown      = 20;             // Levels down
input double          FilterValue     = 0;              // Filter (<=0, for no filter)
input int             FilterPeriod    = 0;              // Filter period (<=0 for using Aroon period)
input enFilterWhat    FilterWhat      = _fltVal;        // Filter what?
input bool            alertsOn        = false;          // Turn alerts on?
input bool            alertsOnCurrent = true;           // Alert on current bar?
input bool            alertsMessage   = true;           // Display messageas on alerts?
input bool            alertsSound     = false;          // Play sound on alerts?
input bool            alertsEmail     = false;          // Send email on alerts?
input bool            alertsNotify    = false;          // Send push notification on alerts?
input bool            Interpolate     = true;           // Interpolate mtf data ?

double osc[],oscc[],oscu[],oscd[],levu[],levd[],prh[],prl[],count[];
int     _mtfHandle = INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),PERIOD_CURRENT,AroonPeriod,PriceHigh,PriceLow,LevelsPeriod,LevelsUp,LevelsDown,FilterValue,FilterPeriod,FilterWhat,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify)

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
   SetIndexBuffer(0,oscu,INDICATOR_DATA);
   SetIndexBuffer(1,oscd,INDICATOR_DATA);
   SetIndexBuffer(2,levu,INDICATOR_DATA);
   SetIndexBuffer(3,levd,INDICATOR_DATA);
   SetIndexBuffer(4,osc  ,INDICATOR_DATA); 
   SetIndexBuffer(5,oscc ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,prh  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,prl  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,count,INDICATOR_CALCULATIONS);
      PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
            timeFrame = MathMax(_Period,TimeFrame);
               if (timeFrame != _Period) _mtfHandle = _mtfCall;
      IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(timeFrame)+" Arron oscillator("+DoubleToString(AroonPeriod,0)+","+(string)LevelsPeriod+")");
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
            if (CopyBuffer(_mtfHandle,8,0,1,result)==-1) return(0); 
      
                //
                //
                //
                //
                //
              
                #define _mtfRatio PeriodSeconds(timeFrame)/PeriodSeconds(_Period)
                int i,limit = MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0));
                for (i=limit; i<rates_total && !_StopFlag; i++ )
                {
                   if (CopyBuffer(_mtfHandle,0,time[i],1,result)==-1) break; oscu[i]  = result[0];
                   if (CopyBuffer(_mtfHandle,1,time[i],1,result)==-1) break; oscd[i]  = result[0];
                   if (CopyBuffer(_mtfHandle,2,time[i],1,result)==-1) break; levu[i]  = result[0];
                   if (CopyBuffer(_mtfHandle,3,time[i],1,result)==-1) break; levd[i]  = result[0];
                   if (CopyBuffer(_mtfHandle,4,time[i],1,result)==-1) break; osc[i]   = result[0];
                   if (CopyBuffer(_mtfHandle,5,time[i],1,result)==-1) break; oscc[i]  = result[0];
                   
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
                            _interpolate(oscu,i,k,n);
                            _interpolate(oscd,i,k,n);
                            _interpolate(osc ,i,k,n);
                         }                            
                }     
                if (i!=rates_total) return(0); return(rates_total);
      }
   
   //
   //
   //
   //
   //
   
   int    lperiod = (LevelsPeriod>0) ? LevelsPeriod : AroonPeriod;
   int    tperiod = (FilterPeriod>0) ? FilterPeriod : AroonPeriod;
   double pfilter = ((FilterWhat&_fltPrc)!=0) ? FilterValue : 0;
   double vfilter = ((FilterWhat&_fltVal)!=0) ? FilterValue : 0;
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      prh[i] = iFilter(getPrice(PriceHigh,open,close,high,low,i,rates_total,0),pfilter,tperiod,i,rates_total,0);
      prl[i] = iFilter(getPrice(PriceLow ,open,close,high,low,i,rates_total,1),pfilter,tperiod,i,rates_total,1);
         if (prl[i]>prh[i]) { double temp=prh[i]; prh[i] = prl[i]; prl[i] = temp; }
            double max = prh[i]; double maxi = 0;
            double min = prl[i]; double mini = 0;
            for (int k=1; k<=AroonPeriod && (i-k)>=0; k++)
            {
               if (max<prh[i-k]) { maxi=k; max = prh[i-k]; }
               if (min>prl[i-k]) { mini=k; min = prl[i-k]; }
            }                  
      osc[i]  = iFilter(100.0*(mini-maxi)/(double)AroonPeriod,vfilter,tperiod,i,rates_total,2);
      oscu[i] = osc[i];
      levu[i] = iQuantile(osc[i],lperiod,LevelsUp  ,i,rates_total);
      levd[i] = iQuantile(osc[i],lperiod,LevelsDown,i,rates_total);
      oscd[i] = MathMax(MathMin(osc[i],levu[i]),levd[i]);
      oscc[i] = (i>0) ? (osc[i]>levu[i]) ? 1 : (osc[i]<levd[i]) ? 2 : 0 : 0;
   }
   manageAlerts(time,oscc,rates_total);
   count[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
   return(rates_total);
}


//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

#define _quantileInstances 1
double _sortQuant[];
double _workQuant[][_quantileInstances];

double iQuantile(double value, int period, double qp, int i, int bars, int instanceNo=0)
{
   if (period<1) return(value);
   if (ArrayRange(_workQuant,0)!=bars) ArrayResize(_workQuant,bars); 
   if (ArraySize(_sortQuant)!=period)  ArrayResize(_sortQuant,period); 
            _workQuant[i][instanceNo]=value;
            int k=0; for (; k<period && (i-k)>=0; k++) _sortQuant[k] = _workQuant[i-k][instanceNo];
                     for (; k<period            ; k++) _sortQuant[k] = 0;
                     ArraySort(_sortQuant);

   //
   //
   //
   //
   //
   
   double index = (period-1.0)*qp/100.00;
   int    ind   = (int)index;
   double delta = index - ind;
   if (ind == NormalizeDouble(index,5))
         return(            _sortQuant[ind]);
   else  return((1.0-delta)*_sortQuant[ind]+delta*_sortQuant[ind+1]);
}   

//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

#define filterInstances 3
double workFil[][filterInstances*3];

#define _fchange 0
#define _fachang 1
#define _fprice  2

double iFilter(double tprice, double filter, int period, int i, int bars, int instanceNo=0)
{
   if (filter<=0) return(tprice);
   if (ArrayRange(workFil,0)!= bars) ArrayResize(workFil,bars); instanceNo*=3;
   
   //
   //
   //
   //
   //
   
   workFil[i][instanceNo+_fprice]  = tprice; if (i<1) return(tprice);
   workFil[i][instanceNo+_fchange] = MathAbs(workFil[i][instanceNo+_fprice]-workFil[i-1][instanceNo+_fprice]);
   workFil[i][instanceNo+_fachang] = workFil[i][instanceNo+_fchange];

   for (int k=1; k<period && (i-k)>=0; k++) workFil[i][instanceNo+_fachang] += workFil[i-k][instanceNo+_fchange];
                                            workFil[i][instanceNo+_fachang] /= period;
    
   double stddev = 0; for (int k=0;  k<period && (i-k)>=0; k++) stddev += MathPow(workFil[i-k][instanceNo+_fchange]-workFil[i-k][instanceNo+_fachang],2);
          stddev = MathSqrt(stddev/(double)period); 
   double filtev = filter * stddev;
   if( MathAbs(workFil[i][instanceNo+_fprice]-workFil[i-1][instanceNo+_fprice]) < filtev ) workFil[i][instanceNo+_fprice]=workFil[i-1][instanceNo+_fprice];
        return(workFil[i][instanceNo+_fprice]);
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

      string message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" Aroon oscillator state changed to "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" Aroon oscillator",message);
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
//

#define priceInstances 2
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