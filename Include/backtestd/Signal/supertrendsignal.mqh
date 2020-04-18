//+------------------------------------------------------------------+
//|                                             SuperTrendSignal.mqh |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//+------------------------------------------------------------------+
//| Included files                                                   |
//+------------------------------------------------------------------+
#property tester_indicator "SuperTrend.ex5"
#include <backtestd\SignalClass\CustomSignal.mqh>
#define PRODUCE_supertrendsignal

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
//+---------------------------------------------------------------------+
//| Description of the class                                            |
//| Title=The signals based on SuperTrend indicator                     |
//| Type=SignalAdvanced                                                 |
//| Name=SuperTrend                                                     |
//| Class=CSuperTrendSignal                                             |
//| Page=                                                               |
//| Parameter=BuyPosOpen,bool,true,Permission to buy                    |
//| Parameter=SellPosOpen,bool,true,Permission to sell                  |
//| Parameter=BuyPosClose,bool,true,Permission to exit a long position  |
//| Parameter=SellPosClose,bool,true,Permission to exit a short position|
//| Parameter=Ind_Timeframe,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe         |
//| Parameter=CCIPeriod,uint,50, CCI indicator period                   |
//| Parameter=ATRPeriod,uint,5,ATR indicator period                     |
//| Parameter=Level,uint,0,CCI activation level                         |
//| Parameter=SignalBar,uint,1,Bar index for entry signal               |
//+---------------------------------------------------------------------+
//--- wizard description end
//+---------------------------------------------------------------------+
//| CSuperTrendSignal class.                                            |
//| Purpose: Class of generator of trade signals based on               |
//| SuperTrend indicator values http://www.mql5.com/ru/code/527/.       |
//|             Is derived from the CExpertSignal class.                |
//+---------------------------------------------------------------------+
class CSuperTrendSignal : public CCustomSignal
  {
protected:
   CiCustom          m_indicator;        // the object for access to SuperTrend values

   //--- adjusted parameters
   bool              m_BuyPosOpen;       // permission to buy
   bool              m_SellPosOpen;      // permission to sell
   bool              m_BuyPosClose;      // permission to exit a long position
   bool              m_SellPosClose;     // permission to exit a short position
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // indicator chart timeframe
   uint              m_CCIPeriod;        // CCI indicator period
   uint              m_ATRPeriod;        // ATR indicator period
   uint              m_Level;            // CCI activation level 
   uint              m_SignalBar;        // bar index for getting entry signal

public:
                     CSuperTrendSignal();

   //--- methods of setting adjustable parameters
   void               BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void               SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void               BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void               SellPosClose(bool value)                { m_SellPosClose=value;     }
   //--- indicator input parameters
   void               Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void               CCIPeriod(uint value)                   { m_CCIPeriod=value;        }
   void               ATRPeriod(uint value)                   { m_ATRPeriod=value;        }
   void               Level(uint value)                       { m_Level=value;            }
   //---
   void               SignalBar(uint value) { m_SignalBar=value;        }

   //--- adjustable parameters validation method
   virtual bool      ValidationSettings();
   //--- adjustable parameters validation method
   virtual bool      InitIndicators(CIndicators *indicators); // indicators initialization
   //--- market entry signals generation method
   virtual int       LongCondition();
   virtual int       ShortCondition();
   virtual int       Side();

   bool              InitSuperTrend(CIndicators *indicators);   // SuperTrend indicator initializing method

private:
   int               m_last_signal;

  };
//+------------------------------------------------------------------+
//| CSuperTrendSignal constructor.                                   |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSuperTrendSignal::CSuperTrendSignal()
  {
//--- setting default parameters
   m_BuyPosOpen=true;
   m_SellPosOpen=true;
   m_BuyPosClose=true;
   m_SellPosClose=true;
   m_last_signal=0.0;

//--- indicator input parameters   
   m_Ind_Timeframe=PERIOD_H4;
   m_CCIPeriod=50;
   m_ATRPeriod=5;
   m_Level=0;
//---  
   m_SignalBar=1;
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Checking adjustable parameters.                                  |
//| INPUT:  no.                                                      |
//| OUTPUT: true if the settings are valid, false - if not.          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSuperTrendSignal::ValidationSettings()
  {
//--- checking parameters
   if(m_CCIPeriod<=0)
     {
      printf(__FUNCTION__+": CCI indicator period must be greater than zero");
      return(false);
     }

   if(m_ATRPeriod<=0)
     {
      printf(__FUNCTION__+": ATR indicator period must be greater than zero");
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
bool CSuperTrendSignal::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- indicator initialization
   if(!InitSuperTrend(indicators)) return(false);

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| SuperTrend indicator initialization.                             |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSuperTrendSignal::InitSuperTrend(CIndicators *indicators)
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
   MqlParam parameters[5];

   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="SuperTrend.ex5";

   parameters[1].type=TYPE_UINT;
   parameters[1].integer_value=m_CCIPeriod;

   parameters[2].type=TYPE_UINT;
   parameters[2].integer_value=m_ATRPeriod;

   parameters[3].type=TYPE_UINT;
   parameters[3].integer_value=m_Level;

   parameters[4].type=TYPE_UINT;
   parameters[4].integer_value=m_Level;
//---
   if(!m_indicator.Create(m_symbol.Name(),m_Ind_Timeframe,IND_CUSTOM,5,parameters))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }

//--- number of buffers
   if(!m_indicator.NumBuffers(4))  return(false);

//--- SuperTrend indicator initialized successfully
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening a long position and              |
//| closing a short one                                              |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CSuperTrendSignal::LongCondition()
  {
//--- buy signal is determined by buffer 2 of the SuperTrend indicator
   double Signal=m_indicator.GetData(2,m_SignalBar);

//--- getting a trading signal 
   if(Signal && Signal!=EMPTY_VALUE)
     {
      return 100;
     }

//--- no trading signal
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening a short position and             |
//| closing a long one                                               |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CSuperTrendSignal::ShortCondition()
  {
//--- sell signal is determined by buffer 3 of the SuperTrend indicator
   double Signal=m_indicator.GetData(3,m_SignalBar);

//--- getting a trading signal 
   if(Signal && Signal!=EMPTY_VALUE)
     {
      return 100;
     }

//--- no trading signal   
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+

int CSuperTrendSignal::Side()
  {
//--- Long trend signal is determined by buffer 0 of the SuperTrend indicator
   double long_trend=m_indicator.GetData(0,m_SignalBar);
   if(long_trend && long_trend!=EMPTY_VALUE) return(100);

//--- Short trend signal is determined by buffer 1 of the SuperTrend indicator
   double short_trend=m_indicator.GetData(1,m_SignalBar);
   if(short_trend && short_trend!=EMPTY_VALUE) return(-100);

//--- no trading signal
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
