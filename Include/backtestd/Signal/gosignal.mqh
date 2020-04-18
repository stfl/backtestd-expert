//+------------------------------------------------------------------+
//|                                                     GoSignal.mqh |
//|                             Copyright � 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//+------------------------------------------------------------------+
//| Included files                                                   |
//+------------------------------------------------------------------+
#property tester_indicator "Indi\Go.ex5"
#include <..\Experts\BacktestExpert\Signal\CustomSignal.mqh>
#define PRODUCE_gosignal

// wizard description start
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
//| Title=The signals based on Go indicator                              |
//| Type=SignalAdvanced                                                  |
//| Name=Go                                                              |
//| Class=CGoSignal                                                      |
//| Page=                                                                |
//| Parameter=BuyPosOpen,bool,true,Permission to buy                     |
//| Parameter=SellPosOpen,bool,true,Permission to sell                   |
//| Parameter=BuyPosClose,bool,true,Permission to exit a long position   |
//| Parameter=SellPosClose,bool,true,Permission to exit a short position |
//| Parameter=Ind_Timeframe,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe          |
//| Parameter=period,uint,174,Smoothing period                           |
//| Parameter=SignalBar,uint,1,Bar index for entry signal                |
//+----------------------------------------------------------------------+
// wizard description end
//+----------------------------------------------------------------------+
//| CGoSignal class.                                                     |
//| Purpose: Class of trade signals generator based on                   |
//| Go indicator http://www.mql5.com/ru/code/440/.                       |
//|             Is derived from the CExpertSignal class.                 |
//+----------------------------------------------------------------------+
class CGoSignal : public CCustomSignal
  {
protected:
   CiCustom          m_indicator;        // the object for access to Go values

   //--- adjusted parameters
   bool              m_BuyPosOpen;       // permission to buy
   bool              m_SellPosOpen;      // permission to sell
   bool              m_BuyPosClose;      // permission to exit a long position
   bool              m_SellPosClose;     // permission to exit a short position
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // Go indicator timeframe
   uint              m_smooth_period;           // Smoothing period 
   uint              m_SignalBar;        // Bar index for getting entry signal 

public:
                     CGoSignal();

   //--- methods of setting adjustable parameters
   void              BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void              SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void              BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void              SellPosClose(bool value)                { m_SellPosClose=value;     }
   void              Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void              period(uint value)                      { m_smooth_period=value;           }
   void              SignalBar(uint value)                   { m_SignalBar=value;        }

   //--- adjustable parameters validation method
   virtual bool      ValidationSettings();
   //--- adjustable parameters validation method
   virtual bool      InitIndicators(CIndicators *indicators); // indicators initialization
   //--- market entry signals generation method
   virtual int       LongCondition();
   virtual int       ShortCondition();

   bool              InitGo(CIndicators *indicators);   // Go indicator initializing method

protected:

  };
//+------------------------------------------------------------------+
//| CGoSignal constructor.                                           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CGoSignal::CGoSignal()
  {
//--- setting default parameters
   m_BuyPosOpen=true;
   m_SellPosOpen=true;
   m_BuyPosClose=true;
   m_SellPosClose=true;
   m_Ind_Timeframe=PERIOD_H4;
   m_smooth_period=174;
   m_SignalBar=1;
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Checking adjustable parameters.                                  |
//| INPUT:  no.                                                      |
//| OUTPUT: true if the settings are valid, false - if not.          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CGoSignal::ValidationSettings()
  {
//--- checking parameters
   if(m_smooth_period<=0)
     {
      printf(__FUNCTION__+": Indicator period must be greater than zero");
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
bool CGoSignal::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- indicator initialization
   if(!InitGo(indicators)) return(false);

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| Go indicator initialization.                                     |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CGoSignal::InitGo(CIndicators *indicators)
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
   MqlParam parameters[2];

   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Indi\Go.ex5";

   parameters[1].type=TYPE_UINT;
   parameters[1].integer_value=m_smooth_period;

//--- object initialization   
   if(!m_indicator.Create(m_symbol.Name(),m_Ind_Timeframe,IND_CUSTOM,2,parameters))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }

//--- number of buffers
   if(!m_indicator.NumBuffers(2)) return(false);

//--- Go indicator initialized successfully
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening a long position and              |
//| closing a short one                                              |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CGoSignal::LongCondition()
  {
//--- buy signal is determined by buffer 1 of the Go indicator
   double Signal0=m_indicator.GetData(1,m_SignalBar);
   double Signal1=m_indicator.GetData(1,m_SignalBar+1);

//--- getting a trading signal 
   if(Signal0==1)
     {
      if(Signal1==2)
        {

         if(m_BuyPosOpen)
           {
            if(m_SellPosClose) return(REVERSE_SHORT);
            else return(OPEN_LONG);
           }

         if(m_SellPosClose) return(CLOSE_SHORT);
        }
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
int CGoSignal::ShortCondition()
  {
//--- sell signal is determined by buffer 1 of the Go indicator
   double Signal0=m_indicator.GetData(1,m_SignalBar);
   double Signal1=m_indicator.GetData(1,m_SignalBar+1);

//--- getting a trading signal 
   if(Signal0==2)
     {
      if(Signal1==1)
        {

         if(m_SellPosOpen)
           {
            if(m_BuyPosClose) return(REVERSE_LONG);
            else return(OPEN_SHORT);
           }

         if(m_BuyPosClose) return(CLOSE_LONG);
        }
     }
//--- no trading signal   
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
