//+------------------------------------------------------------------+
//|                                             BykovTrendSignal.mqh |
//|                             Copyright ? 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright ? 2011, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//+------------------------------------------------------------------+
//| Included files                                                   |
//+------------------------------------------------------------------+
#property tester_indicator "Indi\\BykovTrend.ex5"
#include <..\Experts\BacktestExpert\Signal\CustomSignal.mqh>
#define PRODUCE_bykovtrendsignal                                               \
  if (StringCompare(name, "bykovtrend", false) == 0) {                         \
    CBykovTrendSignal *signal = new CBykovTrendSignal;                         \
    assert_signal;                                                             \
    signal.Ind_Timeframe(time_frame);                                    \
    signal.RISK(inputs[1]);                                             \
    signal.SSP(inputs[0]);                                              \
    signal.SignalBar(shift + (Expert_EveryTick ? 0 : 1));               \
    return signal;                                                             \
  }
//--- wizard description start
//+------------------------------------------------------------------+ 
//|  Declaration of constants                                        |
//+------------------------------------------------------------------+ 
#define OPEN_LONG     80  // The constant for returning the buy command to the Expert Advisor
#define OPEN_SHORT    80  // The constant for returning the sell command to the Expert Advisor
#define CLOSE_LONG    40  // The constant for returning the command to close a long position to the Expert Advisor
#define CLOSE_SHORT   40  // The constant for returning the command to close a short position to the Expert Advisor
#define REVERSE_LONG  100 // The constant for returning the command to reverse a long position to the Expert Advisor
#define REVERSE_SHORT 100 // The constant for returning the command to reverse a short position to the Expert Advisor
#define NO_SIGNAL      0  // The constant for returning the absence of a signal to the Expert Advisor
//+----------------------------------------------------------------------+
//| Description of the class                                             |
//| Title=The signals based on BykovTrend indicator                      |
//| Type=SignalAdvanced                                                  |
//| Name=BykovTrend                                                      |
//| Class=CBykovTrendSignal                                              |
//| Page=                                                                |
//| Parameter=BuyPosOpen,bool,true,Permission to buy                     |
//| Parameter=SellPosOpen,bool,true,Permission to sell                   |
//| Parameter=BuyPosClose,bool,true,Permission to exit a long position   |
//| Parameter=SellPosClose,bool,true,Permission to exit a short position |
//| Parameter=Ind_Timeframe,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe          |
//| Parameter=RISK,int,4,Risk level                                      |
//| Parameter=SSP,int,9,SSP                                              |
//| Parameter=SignalBar,uint,1,Bar index for entry signal                |
//+----------------------------------------------------------------------+
//--- wizard description end
//+----------------------------------------------------------------------+
//| CBykovTrendSignal class.                                             |
//| Purpose: Class of generator of trade signals based on                |
//| BykovTrend indicator http://www.mql5.com/en/code/497/.               |
//|            Is derived from the CExpertSignal class.                  |
//+----------------------------------------------------------------------+
class CBykovTrendSignal : public CCustomSignal
  {
protected:
   CiCustom          m_indicator;        // the object for access to BykovTrend values

   //--- adjusted parameters
   bool              m_BuyPosOpen;       // permission to buy
   bool              m_SellPosOpen;      // permission to sell
   bool              m_BuyPosClose;      // permission to exit a long position
   bool              m_SellPosClose;     // permission to exit a short position
   
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // BykovTrend indicator timeframe
   uint              m_RISK;             // Risk level
   uint              m_SSP;              // SSP
   uint              m_SignalBar;        // bar index for getting entry signal

public:
                     CBykovTrendSignal();

   //--- methods of setting adjustable parameters
   void               BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void               SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void               BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void               SellPosClose(bool value)                { m_SellPosClose=value;     }
   void               Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void               RISK(uint value)                        { m_RISK=value;             }
   void               SSP(uint value)                         { m_SSP=value;              }
   void               SignalBar(uint value)                   { m_SignalBar=value;        }

   //--- adjustable parameters validation method
   virtual bool      ValidationSettings();
   //--- adjustable parameters validation method
   virtual bool      InitIndicators(CIndicators *indicators); // indicators initialization
   //--- market entry signals generation method
   virtual int       LongCondition();
   virtual int       ShortCondition();

   bool              InitBykovTrend(CIndicators *indicators);   // BykovTrend indicator initializing method
  };
//+------------------------------------------------------------------+
//| CBykovTrendSignal constructor.                                   |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CBykovTrendSignal::CBykovTrendSignal()
  {
//--- setting default values
   m_BuyPosOpen=true;

//--- indicator input parameters   
   m_SellPosOpen=true;
   m_BuyPosClose=true;
   m_SellPosClose=true;
   m_Ind_Timeframe=PERIOD_H4;
   m_RISK=4;
   m_SSP=4;
//---  
   m_SignalBar=1;
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Checking adjustable parameters.                                  |
//| INPUT:  no.                                                      |
//| OUTPUT: true, if the settings are valid, false - if not.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBykovTrendSignal::ValidationSettings()
  {
//--- checking parameters
   if(m_RISK<=0)
     {
      printf(__FUNCTION__+": Risk level must be above zero");
      return(false);
     }
     
   if(m_SSP<=0)
     {
      printf(__FUNCTION__+": SSP must be above zero");
      return(false);
     }

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization of indicators and time series.                    |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBykovTrendSignal::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- indicator initialization 
   if(!InitBykovTrend(indicators)) return(false);

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| BykovTrend indicator initialization.                             |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBykovTrendSignal::InitBykovTrend(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- adding an object to the collection
   if(!indicators.Add(GetPointer(m_indicator)))
     {
      printf(__FUNCTION__+": error of adding the object");
      return(false);
     }

//--- setting the indicator parameters
   MqlParam parameters[3];
   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Indi\\BykovTrend.ex5";
   parameters[1].type=TYPE_INT;
   parameters[1].integer_value=m_RISK;
   parameters[2].type=TYPE_INT;
   parameters[2].integer_value=m_SSP;

//--- object initialization   
   if(!m_indicator.Create(m_symbol.Name(),m_Ind_Timeframe,IND_CUSTOM,3,parameters))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }
     
//--- number of buffers
   if(!m_indicator.NumBuffers(2)) return(false);
   
//--- BykovTrend indicator initialized successfully
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening                                  |
//| a long position and closing a short one                          |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CBykovTrendSignal::LongCondition()
  {
//--- buy signal is determined by buffer 1 of the BykovTrend indicator
   double Signal=m_indicator.GetData(1,m_SignalBar);

//--- getting a trading signal 
   if(Signal && Signal!=EMPTY_VALUE)
     {
      if(m_BuyPosOpen)
        {
         if(m_SellPosClose) return(REVERSE_SHORT);
         else return(OPEN_LONG);
        }
      else
        {
         if(m_SellPosClose) return(CLOSE_SHORT);
        }
     }

//--- searching for signals for closing a short position
   if(!m_SellPosClose) return(NO_SIGNAL);

   int Bars_=Bars(m_symbol.Name(),m_Ind_Timeframe);

   for(int bar=int(m_SignalBar); bar<Bars_; bar++)
     {
      Signal=m_indicator.GetData(0,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(NO_SIGNAL);

      Signal=m_indicator.GetData(1,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(CLOSE_SHORT);
     }

//--- no trading signal
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening                                  |
//| a short position and closing a long one                          |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CBykovTrendSignal::ShortCondition()
  {
//--- sell signal is determined by buffer 0 of the BykovTrend indicator
   double Signal=m_indicator.GetData(0,m_SignalBar);
   
//--- getting a trading signal
   if(Signal && Signal!=EMPTY_VALUE)
     {
      if(m_SellPosOpen)
        {
         if(m_BuyPosClose) return(REVERSE_LONG);
         else return(OPEN_SHORT);
        }
      else
        {
         if(m_BuyPosClose) return(CLOSE_LONG);
        }
     }

//--- searching for signals for closing a long position
   if(!m_BuyPosClose) return(NO_SIGNAL);

   int Bars_=Bars(Symbol(),m_Ind_Timeframe);
   for(int bar=int(m_SignalBar); bar<Bars_; bar++)
     {
      Signal=m_indicator.GetData(1,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(NO_SIGNAL);

      Signal=m_indicator.GetData(0,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(CLOSE_LONG);
     }

//--- no trading signal   
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
