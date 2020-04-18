//+------------------------------------------------------------------+
//|                                                 StalinSignal.mqh |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//+------------------------------------------------------------------+
//| Included files                                                   |
//+------------------------------------------------------------------+
#property tester_indicator "Indi\Stalin.ex5"
#include <..\Experts\BacktestExpert\Signal\CustomSignal.mqh>
#define PRODUCE_stalinsignal                                                   \
  if (StringCompare(name, "stalin", false) == 0) {                             \
    CStalinSignal *signal = new CStalinSignal;                                 \
    assert_signal;                                                             \
    signal.Ind_Timeframe(time_frame);                                    \
    signal.SignalBar(shift + (Expert_EveryTick ? 0 : 1));               \
    signal.MAShift(inputs[0]);                                          \
    signal.MAMethod((ENUM_MA_METHOD) inputs[1]);                        \
    signal.Fast(inputs[2]);                                             \
    signal.Slow(inputs[3]);                                             \
    signal.RSI(inputs[4]);                                              \
    signal.Confirm(inputs[5]);                                          \
    signal.Flat(inputs[6]);                                             \
    return signal;                                                             \
  }

//---- wizard description start
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
//| Title=The signals based on Stalin indicator                          |
//| Type=SignalAdvanced                                                  |
//| Name=Stalin                                                          |
//| Class=CStalinSignal                                                  |
//| Page=                                                                |
//| Parameter=BuyPosOpen,bool,true,Permission to buy                     |
//| Parameter=SellPosOpen,bool,true,Permission to sell                   |
//| Parameter=BuyPosClose,bool,true,Permission to exit a long position   |
//| Parameter=SellPosClose,bool,true,Permission to exit a short position |
//| Parameter=Ind_Timeframe,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe          |
//| Parameter=MAMethod,ENUM_MA_METHOD,MODE_EMA,Smoothing period          |
//| Parameter=MAShift,uint,0,moving average shift in bars                |
//| Parameter=Fast,uint,14,fast MA period                                |
//| Parameter=Slow,uint,21,slow MA period                                |
//| Parameter=RSI,uint,17,RSI period                                     |
//| Parameter=Confirm,uint,0,level in points                             |
//| Parameter=Flat,uint,0,flat amplitude in points                       |
//| Parameter=SignalBar,uint,1,Bar index for entry signal                |
//+----------------------------------------------------------------------+
//--- wizard description end
//+----------------------------------------------------------------------+
//| CStalinSignal class.                                                 |
//| Purpose: Class of generator of trade signals based on                |
//| Stalin indicator values http://www.mql5.com/en/code/487/.            |
//| Is derived from the CExpertSignal class.                             |
//+----------------------------------------------------------------------+
class CStalinSignal : public CCustomSignal
  {
protected:
   CiCustom          m_indicator;      // the object for access to Stalin values

   //--- adjusted parameters
   bool              m_BuyPosOpen;     // permission to buy
   bool              m_SellPosOpen;    // permission to sell
   bool              m_BuyPosClose;    // permission to exit a long position
   bool              m_SellPosClose;   // permission to exit a short position
   ENUM_TIMEFRAMES   m_Ind_Timeframe;  // Stalin indicator timeframe
   ENUM_MA_METHOD    m_MAMethod;       // smoothing method
   uint              m_MAShift;        // MA shift in bars  
   uint              m_Fast;           // fast MA period
   uint              m_Slow;           // slow MA period
   uint              m_RSI;            // RSI period
   uint              m_Confirm;        // level in points
   uint              m_Flat;           // MA shift in bars  
   uint              m_SignalBar;      // flat amplitude in points

public:
                     CStalinSignal();

   //--- methods of setting adjustable parameters
   void               BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void               SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void               BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void               SellPosClose(bool value)                { m_SellPosClose=value;     }
   void               Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void               MAMethod(ENUM_MA_METHOD value)          { m_MAMethod=value;         }
   void               MAShift(uint value)                     { m_MAShift=value;          }
   void               Fast(uint value)                        { m_Fast=value;             }
   void               Slow(uint value)                        { m_Slow=value;             }
   void               RSI(uint value)                         { m_RSI=value;              }
   void               Confirm(uint value)                     { m_Confirm=value;          }
   void               Flat(uint value)                        { m_Flat=value;             }
   void               SignalBar(uint value)                   { m_SignalBar=value;        }

   //--- adjustable parameters validation method
   virtual bool      ValidationSettings();
   //--- adjustable parameters validation method
   virtual bool      InitIndicators(CIndicators *indicators); // indicators initialization
   //--- market entry signals generation method
   virtual int       LongCondition();
   virtual int       ShortCondition();
   
   //--- Stalin indicator initializing method
   bool              InitStalin(CIndicators *indicators);
   
protected:

  };
//+------------------------------------------------------------------+
//| CStalinSignal constructor.                                       |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CStalinSignal::CStalinSignal()
  {
//--- setting default values
   m_BuyPosOpen=true;
   m_SellPosOpen=true;
   m_BuyPosClose=true;
   m_SellPosClose=true;

//--- indicator input parameters
   m_Ind_Timeframe=PERIOD_H4;
   m_MAShift=0;
   m_MAMethod=MODE_EMA;
   m_Fast=14;
   m_Slow=21;
   m_RSI=17;
   m_Confirm=0;
   m_Flat=0;
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
bool CStalinSignal::ValidationSettings()
  {
//--- checking parameters
   if(m_Fast==0)
     {
      printf(__FUNCTION__+": fast MA period cannot be equal to zero");
      return(false);
     }
     
   if(m_Slow==0)
     {
      printf(__FUNCTION__+": slow MA period cannot be equal to zero");
      return(false);
     }
     
   if(m_Slow==0)
     {
      printf(__FUNCTION__+": RSI period cannot be equal to zero");
      return(false);
     }

   if((m_Slow - m_Fast) < 3 || (m_Slow - m_Fast) > 15)
     {
      printf(__FUNCTION__+": The Difference between Fast and Slow must be in [3 : 15]");
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
bool CStalinSignal::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- indicator initialization
   if(!InitStalin(indicators)) return(false);

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| Stalin indicator initialization.                                 |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CStalinSignal::InitStalin(CIndicators *indicators)
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
   MqlParam parameters[10];

   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Indi\\Stalin.ex5";
   
   parameters[1].type=TYPE_UINT;
   parameters[1].integer_value=MODE_EMA;

   parameters[2].type=TYPE_UINT;
   parameters[2].integer_value=m_MAShift;

   parameters[3].type=TYPE_UINT;
   parameters[3].integer_value=m_Fast;

   parameters[4].type=TYPE_UINT;
   parameters[4].integer_value=m_Slow;

   parameters[5].type=TYPE_UINT;
   parameters[5].integer_value=m_RSI;

   parameters[6].type=TYPE_UINT;
   parameters[6].integer_value=m_Confirm;

   parameters[7].type=TYPE_UINT;
   parameters[7].integer_value=m_Flat;
   
   parameters[8].type=TYPE_UINT;
   parameters[8].integer_value=0;

   parameters[9].type=TYPE_UINT;
   parameters[9].integer_value=0;

//--- object initialization   
   if(!m_indicator.Create(m_symbol.Name(),m_Ind_Timeframe,IND_CUSTOM,10,parameters))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }

//--- number of buffers
   if(!m_indicator.NumBuffers(2))  return(false);
   
//--- Stalin indicator initialized successfully

   return(true);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening a long position and              |
//| closing a short one                                              |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CStalinSignal::LongCondition()
  {
//--- buy signal is determined by buffer 1 of the Stalin indicator
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
//| Checking conditions for opening a short position and             |
//| closing a long one                                               |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CStalinSignal::ShortCondition()
  {
//--- sell signal is determined by buffer 0 of the Stalin indicator
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
