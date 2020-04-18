//+------------------------------------------------------------------+
//|                                                  SidusSignal.mqh |
//|                             Copyright © 2011,   Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//+------------------------------------------------------------------+
//| Included files                                                   |
//+------------------------------------------------------------------+
#property tester_indicator "Indi\\Sidus.ex5"
#include <..\Experts\BacktestExpert\Signal\CustomSignal.mqh>
#define PRODUCE_sidussignal

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
//| Title=The signals based on Sidus indicator                           |
//| Type=SignalAdvanced                                                  |
//| Name=Sidus                                                           |
//| Class=CSidusSignal                                                   |
//| Page=                                                                |
//| Parameter=BuyPosOpen,bool,true,Permission to buy                     |
//| Parameter=SellPosOpen,bool,true,Permission to sell                   |
//| Parameter=BuyPosClose,bool,true,Permission to exit a long position   |
//| Parameter=SellPosClose,bool,true,Permission to exit a short position |
//| Parameter=Ind_Timeframe,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe          |
//| Parameter=FastEMA,uint,18,Fast EMA period                            |
//| Parameter=SlowEMA,uint,28,Slow EMA period                            |
//| Parameter=FastLWMA,uint,5,Fast LWMA period                           |
//| Parameter=SlowLWMA,uint,8,Slow LWMA period                           |
//| Parameter=IPC,ENUM_APPLIED_PRICE,PRICE_CLOSE,Applied price           |
//| Parameter=Digit,uint,4,Range in points                               |
//| Parameter=SignalBar,uint,1,Bar index for entry signal                |
//+----------------------------------------------------------------------+
//--- wizard description end
//+----------------------------------------------------------------------+
//| CSidusSignal class.                                                  |
//| Purpose: Class of trade signals generator based on                   |
//| Sidus indicator http://www.mql5.com/en/code/751/.                    |
//| Is derived from the CExpertSignal class.                             |
//+----------------------------------------------------------------------+
class CSidusSignal : public CCustomSignal
  {
protected:
   CiCustom          m_indicator;        // the object for access to Sidus values

   //--- adjusted parameters
   bool              m_BuyPosOpen;       // permission to buy
   bool              m_SellPosOpen;      // permission to sell
   bool              m_BuyPosClose;      // permission to exit a long position
   bool              m_SellPosClose;     // permission to exit a short position
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // Sidus indicator timeframe

   uint              m_FastEMA;          // fast EMA period
   uint              m_SlowEMA;          // slow EMA period
   uint              m_FastLWMA;         // fast LWMA period
   uint              m_SlowLWMA;         // slow LWMA period
   uint              m_IPC;              // applied price
   uint              m_Digit;            // range in points
   uint              m_SignalBar;        // bar index for entry signal

public:
                     CSidusSignal();

   //--- methods of setting adjustable parameters
   void               BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void               SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void               BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void               SellPosClose(bool value)                { m_SellPosClose=value;     }
   void               Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void               FastEMA(uint value)                     { m_FastEMA=value;          }
   void               SlowEMA(uint value)                     { m_SlowEMA=value;          }
   void               FastLWMA(uint value)                    { m_FastLWMA=value;         }
   void               SlowLWMA(uint value)                    { m_SlowLWMA=value;         }
   void               IPC(uint value)                         { m_IPC=value;              }
   void               Digit(uint value)                       { m_Digit=value;            }
   void               SignalBar(uint value)                   { m_SignalBar=value;        }

   //--- adjustable parameters validation method
   virtual bool      ValidationSettings();
   //--- adjustable parameters validation method
   virtual bool      InitIndicators(CIndicators *indicators); // indicators initialization
   //--- market entry signals generation method
   virtual int       LongCondition();
   virtual int       ShortCondition();

   bool              InitSidus(CIndicators *indicators);   // Sidus indicator initializing method

protected:

  };
//+------------------------------------------------------------------+
//| CSidusSignal constructor.                                        |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSidusSignal::CSidusSignal()
  {
//--- setting default values
   m_BuyPosOpen=true;
   m_SellPosOpen=true;
   m_BuyPosClose=true;
   m_SellPosClose=true;

//--- indicator input parameters
   m_Ind_Timeframe=PERIOD_H4;
   m_FastEMA=18;
   m_SlowEMA=28;
   m_FastLWMA=5;
   m_SlowLWMA=8;
   m_IPC=PRICE_CLOSE;
   m_Digit=0;

   m_SignalBar=1;
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Checking adjustable parameters.                                  |
//| INPUT:  no.                                                      |
//| OUTPUT: true, if the settings are valid, false - if not.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSidusSignal::ValidationSettings()
  {
//--- checking parameters
   if(m_FastEMA<=0)
     {
      printf(__FUNCTION__+": Fast EMA period must be greater than zero");
      return(false);
     }

   if(m_SlowEMA<=0)
     {
      printf(__FUNCTION__+": Slow EMA period must be greater than zero");
      return(false);
     }

   if(m_FastLWMA<=0)
     {
      printf(__FUNCTION__+": Fast LWMA period must be greater than zero");
      return(false);
     }

   if(m_SlowLWMA<=0)
     {
      printf(__FUNCTION__+": Slow LWMA period must be greater than zero");
      return(false);
     }
    if((m_SlowEMA - m_FastEMA) < 3 || (m_SlowEMA - m_FastEMA) > 10)
     {
      printf(__FUNCTION__+": The Difference between Fast LWMA and Slow LWMA must be in [3 : 10]");
      return(false);
     }
   if((m_SlowLWMA - m_FastLWMA) < 5 || (m_SlowLWMA - m_FastLWMA) > 15)
     {
      printf(__FUNCTION__+": The Difference between Fast EMA and Slow EMA must be in [5 : 15]");
      return(false);
     }
   if((m_SlowLWMA - m_FastEMA) < 3)
     {
      printf(__FUNCTION__+": Fast EMA period must be greater (+3) than Slow LWMA");
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
bool CSidusSignal::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- indicator initialization
   if(!InitSidus(indicators)) return(false);

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| Sidus indicator initialization.                                  |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSidusSignal::InitSidus(CIndicators *indicators)
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
   MqlParam parameters[7];

   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Indi\\Sidus.ex5";

   parameters[1].type=TYPE_INT;
   parameters[1].integer_value=m_FastEMA;

   parameters[2].type=TYPE_INT;
   parameters[2].integer_value=m_SlowEMA;

   parameters[3].type=TYPE_INT;
   parameters[3].integer_value=m_FastLWMA;

   parameters[4].type=TYPE_INT;
   parameters[4].integer_value=m_SlowLWMA;

   parameters[5].type=TYPE_INT;
   parameters[5].integer_value=m_IPC;

   parameters[6].type=TYPE_INT;
   parameters[6].integer_value=m_Digit;

//--- object initialization
   if(!m_indicator.Create(m_symbol.Name(),m_Ind_Timeframe,IND_CUSTOM,7,parameters))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }

//--- number of buffers
   if(!m_indicator.NumBuffers(6)) return(false);

//--- Sidus indicator initialized successfully
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening a long position and              |
//| closing a short one                                              |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CSidusSignal::LongCondition()
  {
//--- buy signal is determined by buffer 0 of the Sidus indicator
   double Signal=m_indicator.GetData(0,m_SignalBar);

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
      Signal=m_indicator.GetData(1,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(NO_SIGNAL);

      Signal=m_indicator.GetData(0,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(CLOSE_SHORT);
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
int CSidusSignal::ShortCondition()
  {
//--- sell signal is determined by buffer 1 of the Sidus indicator
   double Signal=m_indicator.GetData(1,m_SignalBar);

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
      Signal=m_indicator.GetData(0,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(NO_SIGNAL);

      Signal=m_indicator.GetData(1,bar);
      if(Signal && Signal!=EMPTY_VALUE) return(CLOSE_LONG);
     }

//--- no trading signal
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
