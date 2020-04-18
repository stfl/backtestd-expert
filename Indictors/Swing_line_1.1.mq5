//------------------------------------------------------------------
#property copyright "© mladen, 2016, MetaQuotes Software Corp."
#property link      "www.forex-tsd.com, www.mql5.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "Swing line"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrLimeGreen,clrPaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

//
//
//
//
//

input ENUM_TIMEFRAMES  TimeFrame       = PERIOD_CURRENT; // Time frame
input bool             AlertsOn        = false;          // Turn alerts on?
input bool             AlertsOnCurrent = true;           // Alert on current bar?
input bool             AlertsMessage   = true;           // Display messages on alerts?
input bool             AlertsSound     = false;          // Play sound on alerts?
input bool             AlertsEmail     = false;          // Send email on alerts?
input bool             AlertsNotify    = false;          // Send push notification on alerts?
input bool             Interpolate     = true;           // Interpolate in multi time frame mode?

double swli[],swlic[],count[];
ENUM_TIMEFRAMES timeFrame;

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
   SetIndexBuffer(0,swli ,INDICATOR_DATA); 
   SetIndexBuffer(1,swlic,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(2,count,INDICATOR_CALCULATIONS); 
      timeFrame = MathMax(_Period,TimeFrame);
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


double  work[][5];
#define hHi   0
#define hLo   1
#define lHi   2
#define lLo   3
#define trend 4


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

   if (Bars(_Symbol,_Period)<rates_total) return(0);
      //
      //
      //
      //
      //

      if (timeFrame!=_Period)
      {
         double result[]; datetime currTime[],nextTime[]; 
         static int indHandle =-1;
                if (indHandle==-1) indHandle = iCustom(_Symbol,timeFrame,getName(),PERIOD_CURRENT,AlertsOn,AlertsOnCurrent,AlertsMessage,AlertsSound,AlertsEmail,AlertsNotify);
                if (indHandle==-1)                          return(0);
                if (CopyBuffer(indHandle,2,0,1,result)==-1) return(0); 
             
                //
                //
                //
                //
                //
              
                #define _processed EMPTY_VALUE-1
                int i,limit = rates_total-(int)MathMin(result[0]*PeriodSeconds(timeFrame)/PeriodSeconds(_Period),rates_total); 
                for (limit=MathMax(limit,0); limit>0 && !IsStopped(); limit--) if (count[limit]==_processed) break;
                for (i=MathMin(limit,MathMax(prev_calculated-1,0)); i<rates_total && !IsStopped(); i++    )
                {
                   if (CopyBuffer(indHandle,0,time[i],1,result)==-1) break; swli[i]  = result[0];
                   if (CopyBuffer(indHandle,1,time[i],1,result)==-1) break; swlic[i] = result[0];
                                                                            count[i] = _processed;

                   //
                   //
                   //
                   //
                   //
                                      
                   #define _interpolate(buff,i,k,n) buff[i-k] = buff[i]+(buff[i-n]-buff[i])*k/n
                   if (!Interpolate) continue;  CopyTime(_Symbol,TimeFrame,time[i  ],1,currTime); 
                       if (i<(rates_total-1)) { CopyTime(_Symbol,TimeFrame,time[i+1],1,nextTime); if (currTime[0]==nextTime[0]) continue; }
                       int n,k;
                          for(n=1; (i-n)> 0 && time[i-n] >= currTime[0]; n++) continue;	
                          for(k=1; (i-k)>=0 && k<n; k++) _interpolate(swli,i,k,n);
                }
                if (i!=rates_total) return(0); return(rates_total);
      }

   //
   //
   //
   //
   //

   if (ArrayRange(work,0)!=rates_total) ArrayResize(work,rates_total);
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
      {
         work[i][trend] = (i>0) ? work[i-1][trend] : -1;
         work[i][hHi]   = (i>0) ? work[i-1][hHi] : high[i];  work[i][hLo] = (i>0) ? work[i-1][hLo] : low[i]; 
         work[i][lHi]   = (i>0) ? work[i-1][lHi] : high[i];  work[i][lLo] = (i>0) ? work[i-1][lLo] : low[i]; 
         if (i>0 && work[i-1][trend] == 1)
         {
            work[i][hHi] = MathMax(work[i-1][hHi],high[i]);
            work[i][hLo] = MathMax(work[i-1][hLo],low[i]);
            if (high[i]<work[i][hLo]) { work[i][trend] = -1; work[i][lHi] = high[i]; work[i][lLo] = low[i]; }
         }
         if (i>0 && work[i-1][trend] == -1)
         {
            work[i][lHi] = MathMin(work[i-1][lHi],high[i]);
            work[i][lLo] = MathMin(work[i-1][lLo],low[i]);
            if (low[i]>work[i][lHi]) { work[i][trend] =  1; work[i][hHi] = high[i]; work[i][hLo] = low[i]; }
         }
         swli[i]  = (work[i][trend]==1) ? work[i][hLo] : (work[i][trend]==-1) ? work[i][lHi] : close[i];
         swlic[i] = (work[i][trend]==1) ? 1 : (work[i][trend]==-1) ? 2 : 0;
   }
   count[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
   manageAlerts(time,swlic,rates_total);
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

void manageAlerts(const datetime& time[], double& ttrend[], int bars)
{
   if (!AlertsOn) return;
      int whichBar = bars-1; if (!AlertsOnCurrent) whichBar = bars-2; datetime time1 = time[whichBar];
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

      message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" swing line state changed to "+doWhat;
         if (AlertsMessage) Alert(message);
         if (AlertsEmail)   SendMail(_Symbol+" swing line",message);
         if (AlertsNotify)  SendNotification(message);
         if (AlertsSound)   PlaySound("alert2.wav");
   }
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

string getName()
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